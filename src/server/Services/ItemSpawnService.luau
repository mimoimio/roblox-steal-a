local ItemSpawnService = {}
ItemSpawnService.__index = ItemSpawnService

local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type Item = sharedtypes.Item
type ItemConfig = sharedtypes.ItemConfig
type VariationConfig = sharedtypes.VariationConfig
type TierConfig = sharedtypes.TierConfig
type PlayerData = sharedtypes.PlayerData

-- Registry of spawned item models to their metadata
-- [Model] = { itemId: string, displayName: string?, position: Vector3 }
ItemSpawnService.Collections = {}

local ProximityPromptService = game:GetService("ProximityPromptService")

local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local Item = require(game.ServerScriptService.Server.Classes.Item)
local GridService = require(script.Parent.GridService)
local VariationRNGService = require(script.Parent.VariationRNGService)

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
local itemConfigById: { [string]: ItemConfig } = {}

for _, child in ipairs(folder:GetChildren()) do
	if child:IsA("ModuleScript") then
		local config: ItemConfig = require(child)
		table.insert(itemConfigs, config)
		itemConfigById[config.ItemId] = config
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

	-- Tier Display
	local tier = TiersConfig[cfg.Tier]

	-- Name, Variation, Tier, and Rate Display
	local namelabel: TextLabel = model.PrimaryPart.BillboardGui:FindFirstChild("TextLabel")
	local name = cfg.DisplayName
	local varColor = varcfg.ColorPrimary:ToHex()
	local varName = varcfg.DisplayName
	local tierColor = tier.ColorPrimary:ToHex()
	local tierName = tier.DisplayName
	local rate = cfg.Rate * (varcfg.Multiplier or 1)

	local text
	if varcfg.VariationId ~= "none" then
		text = --
			([[<font size="48">%s</font>
<font color="#%s">%s</font> | <font color="#%s">%s</font>
<font>%s/s</font>]]):format(name, varColor, varName, tierColor, tierName, rate)
	else
		text = --
			([[<font>%s</font>
<font color="#%s">%s</font>
<font>%s/s</font>]]):format(name, tierColor, tierName, rate)
	end
	namelabel.Text = text
	safeSetAttributes(model, cfg)
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

	-- Track for cleanup on trigger
	ItemSpawnService.Collections[model] = {
		itemId = itemId,
		displayName = cfg.DisplayName,
		position = position,
		varid = varcfg.VariationId,
	}
end

function ItemSpawnService.initialize()
	-- Container for spawned items
	local itemsFolder = workspace:FindFirstChild("ItemsFolder") or Instance.new("Folder", workspace)
	itemsFolder.Name = "ItemsFolder"
	VariationRNGService.initialize()

	-- setenabled phsyics
	for i, m: Model in game.ReplicatedStorage.Shared.Models:GetChildren() do
		local humanoid: Humanoid = m:FindFirstChild("Humanoid")
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		end
	end

	-- Wait for grid to generate some usable positions
	task.spawn(function()
		if not GridService.isInitialized then
			local start = tick()
			GridService.Initialized:Wait()
			warn(("GridService initialized in %4.4f"):format(tick() - start))
		else
			warn("GridService.isInitialized")
		end

		for i = 1, 100 do
			local ic = itemConfigs[rng:NextInteger(1, #itemConfigs)]
			local tier = TiersConfig[rng:NextInteger(1, #TiersConfig)]
			local variation = VariationRNGService:roll()

			if not ic or typeof(ic) ~= "table" or not ic.ItemId then
				warn("Invalid item config in", itemConfigs)
				continue
			end

			local pos: Vector3? = nil
			if #GridService.Positions > 0 then
				pos = GridService.RemoveRandom()
			end

			if not pos then
				-- If grid ran out, synthesize a simple position spread
				local theta = (i / 100) * math.pi * 2
				pos = Vector3.new(math.cos(theta), 0, math.sin(theta)) * 100
			end

			spawnOne(ic, variation, pos, itemsFolder)
		end
	end)

	local processing = {}
	-- Single global handler for all prompts we create
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		local model = prompt:FindFirstAncestorOfClass("Model")
		if not model then
			return
		end
		local meta = ItemSpawnService.Collections[model]
		if not meta then
			return -- not ours
		end

		if processing[prompt] then
			return
		end
		processing[prompt] = true
		prompt.Enabled = false
		prompt.ActionText = "Picking up..."

		Item.new(meta.itemId, player, meta.varid)
		GridService.InsertPosition(meta.position)
		ItemSpawnService.Collections[model] = nil
		model:Destroy()
		processing[prompt] = nil
		-- spawnOne(itemConfigById[meta.itemId], GridService.RemoveRandom(), itemsFolder)
		spawnOne(
			itemConfigs[rng:NextInteger(1, #itemConfigs)],
			VariationRNGService:roll(),
			GridService.RemoveRandom(),
			itemsFolder
		)
	end)
end

return ItemSpawnService
-- return { initialize = function() end }
