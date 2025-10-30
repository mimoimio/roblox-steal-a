local ItemSpawnService = {}
ItemSpawnService.__index = ItemSpawnService

local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type Item = sharedtypes.Item
type ItemConfig = sharedtypes.ItemConfig
type VariationConfig = sharedtypes.VariationConfig
type TierConfig = sharedtypes.TierConfig
type PlayerData = sharedtypes.PlayerData

ItemSpawnService.Collections = {}

local ProximityPromptService = game:GetService("ProximityPromptService")

local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local Item = require(game.ServerScriptService.Server.Classes.Item)
local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
local GridService = require(script.Parent.GridService)
local FormatItemLabelText = require(game.ReplicatedStorage.Shared.Utils.Format).FormatItemLabelText
local VariationRNGService = require(script.Parent.VariationRNGService)
local TierRNGService = require(script.Parent.TierRNGService)

local VariationsConfig: { VariationConfig } = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
local TiersConfig: { TierConfig } = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)
local rng = Random.new()

local function safeSetAttributes(model: Model, cfg: {})
	for k, v in pairs(cfg) do
		local t = typeof(v)
		if t == "string" or t == "number" or t == "boolean" or t == "Color3" or t == "BrickColor" then
			pcall(function()
				model:SetAttribute(k, v)
			end)
		end
	end
end

local function ensurePrimaryPart(model: Model): BasePart?
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	-- fallback: first BasePart
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			model.PrimaryPart = d
			return d
		end
	end
	return nil
end

local function createPrompt(parentPart: BasePart): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.MaxActivationDistance = parentPart.Parent:IsA("Model")
			and (function(): Vector3
				local c, v = (parentPart.Parent :: Model):GetBoundingBox()
				return v
			end)().Magnitude
		or 6
	pp.KeyboardKeyCode = Enum.KeyCode.F
	pp.GamepadKeyCode = Enum.KeyCode.ButtonL3
	pp.RequiresLineOfSight = false
	pp.HoldDuration = 0
	pp.Parent = parentPart
	return pp
end

local folder = game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("ItemsConfig")
local itemConfigs: { ItemConfig } = {}
local ICSortedByTiers: { [string]: { ItemConfig } } = {}

local itemConfigById: { [string]: ItemConfig } = {}

for _, child in ipairs(folder:GetChildren()) do
	if child:IsA("ModuleScript") then
		local config: ItemConfig = require(child)
		table.insert(itemConfigs, config)
		itemConfigById[config.ItemId] = config
	end
end

for i, itemconfig in itemConfigs do
	if not ICSortedByTiers[itemconfig.TierId] then
		ICSortedByTiers[itemconfig.TierId] = { itemconfig }
	else
		table.insert(ICSortedByTiers[itemconfig.TierId], itemconfig)
	end
end

if #itemConfigs == 0 then
	warn("No item configs found under Shared/Configs/ItemsConfig")
	return
end

local function spawnOne(cfg: ItemConfig, varcfg: VariationConfig, position: Vector3, container: Instance)
	local itemId: string = cfg.ItemId
	if not itemId then
		warn("Item config missing ItemId; skipping")
		return
	end

	local modelsFolder = game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Models")
	local template = modelsFolder:FindFirstChild(itemId)
	if not template or not template:IsA("Model") then
		warn("No model found for ItemId", itemId)
		return
	end

	local model = template:Clone()
	local humanoid: Humanoid = model:FindFirstChild("Humanoid")
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	end

	-- Name, Variation, Tier, and Rate Display
	local namelabel: TextLabel = model.PrimaryPart.BillboardGui:FindFirstChild("TextLabel")
	local text = FormatItemLabelText({
		ItemId = cfg.ItemId,
		TierId = cfg.TierId,
		VariationId = varcfg.VariationId,
		Rate = cfg.Rate * varcfg.Multiplier,
	})
	namelabel.Text = text

	safeSetAttributes(model, cfg)

	if varcfg.VariationId == "strange" then
		local strangelabel: BillboardGui = game.ReplicatedStorage.Shared.StrangeBBGui:Clone()
		local strangebeam: Part = game.ReplicatedStorage.Shared.strangebeam:Clone()
		strangelabel.Parent = model.PrimaryPart
		game.ReplicatedStorage.Shared.Events.StrangeSpawned:FireAllClients()
		strangebeam:PivotTo(model:GetPivot())
		strangebeam.Parent = model
	elseif varcfg.VariationId == "starlight" then
		local starlightbeam: Part = game.ReplicatedStorage.Shared.starlightbeam:Clone()
		starlightbeam:PivotTo(model:GetPivot())
		starlightbeam.Parent = model
	end

	model.Parent = container
	local primary = ensurePrimaryPart(model)
	if not primary then
		warn("Model has no BasePart to attach prompt:", model:GetFullName())
		model:Destroy()
		return
	end
	primary.Anchored = true

	-- Place it
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.random() * 2 * math.pi, 0))

	-- Prompt
	local pp = createPrompt(primary)
	pp.ActionText = "Pick up"
	pp.ObjectText = tostring(cfg.DisplayName or itemId)
	pp.Name = "PickupPrompt"

	-- Track for cleanup on trigger + lifecycle (add spawnTime & destroy task)
	local lifeMeta = {
		itemId = itemId,
		displayName = cfg.DisplayName,
		position = position,
		varid = varcfg.VariationId,
		spawnTime = tick(),
	}
	ItemSpawnService.Collections[model] = lifeMeta

	-- Lifespan 30-40s then recycle if still present (not picked up)
	local lifeSeconds = (4 + math.random()) * 10
	task.delay(lifeSeconds, function()
		-- If still in collections (not picked up)
		if ItemSpawnService.Collections[model] == lifeMeta and model.Parent then
			-- Return position and remove, then immediately spawn a replacement
			GridService.InsertPosition(position)
			ItemSpawnService.Collections[model] = nil
			model:Destroy()
			-- Replacement spawn
			local ICsFromTier
			repeat
				ICsFromTier = ICSortedByTiers[TierRNGService:roll().TierId]
			until ICsFromTier
			local IC = ICsFromTier[rng:NextInteger(1, #ICsFromTier)]

			spawnOne(IC, VariationRNGService:roll(IC.Variations), GridService.RemoveRandom() or position, container)
		end
	end)
end

-- function ItemSpawnService.start()
-- 	if ItemSpawnService.isStarted then
-- 		return
-- 	end
-- 	ItemSpawnService.isStarted = true
-- 	-- Container for spawned items
-- 	local itemsFolder = workspace:FindFirstChild("ItemsFolder") or Instance.new("Folder", workspace)
-- 	itemsFolder.Name = "ItemsFolder"

-- 	-- setenabled phsyics
-- 	for i, m: Model in game.ReplicatedStorage.Shared.Models:GetChildren() do
-- 		local humanoid: Humanoid = m:FindFirstChild("Humanoid")
-- 		if humanoid then
-- 			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
-- 		end
-- 	end

-- 	-- Wait for grid to generate some usable positions
-- 	task.spawn(function()
-- 		if not GridService.isInitialized then
-- 			GridService.Initialized:Wait()
-- 		end

-- 		for i = 1, 150 do
-- 			local t = TierRNGService:roll()
-- 			local ICsFromTier = ICSortedByTiers[t.TierId]

-- 			if not ICsFromTier then
-- 				i -= 1
-- 				continue
-- 			end

-- 			local IC = ICsFromTier[rng:NextInteger(1, #ICsFromTier)]
-- 			local tier = TiersConfig[rng:NextInteger(1, #TiersConfig)]
-- 			local variation = VariationRNGService:roll(IC.Variations)

-- 			if not IC or typeof(IC) ~= "table" or not IC.ItemId then
-- 				warn("Invalid item config in", itemConfigs)
-- 				continue
-- 			end

-- 			local pos: Vector3? = nil
-- 			if #GridService.Positions > 0 then
-- 				pos = GridService.RemoveRandom()
-- 			end

-- 			if not pos then
-- 				-- If grid ran out, synthesize a simple position spread
-- 				local theta = (i / 100) * math.pi * 2
-- 				pos = Vector3.new(math.cos(theta), 0, math.sin(theta)) * 100
-- 			end

-- 			spawnOne(IC, variation, pos, itemsFolder)
-- 		end
-- 	end)

-- 	local processing = {}
-- 	-- Single global handler for all prompts we create
-- 	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
-- 		local model = prompt:FindFirstAncestorOfClass("Model")
-- 		if not model then
-- 			return
-- 		end
-- 		local meta = ItemSpawnService.Collections[model]
-- 		if not meta then
-- 			return -- not ours
-- 		end

-- 		if processing[prompt] then
-- 			return
-- 		end
-- 		local ActionText = prompt.ActionText
-- 		processing[prompt] = true
-- 		prompt.Enabled = false
-- 		prompt.ActionText = "Picking up..."

-- 		local success: Item = Item.new(meta.itemId, player, meta.varid)
-- 		if success then
-- 			GridService.InsertPosition(meta.position)
-- 			ItemSpawnService.Collections[model] = nil
-- 			model:Destroy()
-- 			processing[prompt] = nil
-- 		else
-- 			processing[prompt] = nil
-- 			prompt.Enabled = true
-- 			prompt.ActionText = ActionText
-- 		end
-- 	end)
-- end

function ItemSpawnService.start()
	local Events = game.ReplicatedStorage.Shared.Events
	local MoneyDisplayUpdate: UnreliableRemoteEvent = Events:WaitForChild("MoneyDisplayUpdate")
	warn(itemConfigs)
	local mdfolder = game.ReplicatedStorage.Shared.Models
	for i, itemconfig in itemConfigs do
		warn(i)
		local model: Model = (mdfolder:FindFirstChild(itemconfig.ItemId) or mdfolder:FindFirstChild("error")):Clone()
		model.Parent = workspace
		model:PivotTo(CFrame.new(i * 10, 10, 10))
		local pp = Instance.new("ProximityPrompt", model)
		pp.ActionText = itemconfig.Price or "-" .. " coins"
		pp.ObjectText = itemconfig.DisplayName
		pp.KeyboardKeyCode = Enum.KeyCode.F
		task.delay(1, function()
			model.PrimaryPart.Anchored = true
		end)
		pp.Triggered:Connect(function(player)
			local pd = PlayerData.Collections[player]
			local money = pd.Resources.Money
			money -= itemconfig.Price
			if money <= 0 then
				return
			end
			if not Item.new(itemconfig.ItemId, player) then
				return
			end

			pd.Resources.Money = money
			MoneyDisplayUpdate:FireClient(player, pd.Resources.Money, pd.Resources.Rate)
		end)
	end
end

return ItemSpawnService
--[[

	IngredientSpawnService, actually.
	Uses VariationRNGService and TierRNGService to randomly spawn ingredients.
	Picked up ingredients can be
	- Placed
	- Merged
	- Permenantly remove

	You have your core Generator.
	You either
	MERGE the generator with materials (items), immediately adds the rate Once to your core, or
	PLACE the ingredients in the collectors slot, adding money every second
	ABSTRACT the ingredients, add life spans to a placed collector, delaying it's expiration

	Item may have side effects. Types:
	- Entry: 		takes effect after FIRST placed.
	- Merged: 		after merging
	- Removed: 		after Removed

]]
