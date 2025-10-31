local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useRef = React.useRef

local Dummies = require(script.Parent.Dummies)
local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)
local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
local ICDummies = Dummies.ItemConfigs
local PDDummy = Dummies.PlayerData
local ProfileStore = require(game.ServerScriptService.Server.Services.ProfileStore)

type PlayerData = PlayerData.PlayerData
type Profile = ProfileStore.Profile<PlayerData>

local Plots = workspace.Plots:GetChildren()
local PlayerPlot = {}

local function getPlot(): Model?
	while #Plots <= 0 do
		warn("waiting for plots", Plots)
		Plots = workspace.Plots:GetChildren()
		task.wait()
	end
	return table.remove(Plots, #Plots)
end

local function addPlot(plot: Model): boolean?
	table.insert(Plots, plot)
	return true
end

local function getPlotFromPlayer(player: Player): Model?
	return PlayerPlot[player]
end

local function Item(props: {
	Owned: boolean,
	ItemId: string,
	Price: number,
	RootArea: Part,
	Profile: Profile,
	triggerSetPlayer: () -> nil,
	BuyButton: (ItemId: string) -> nil,
})
	useEffect(function()
		local button: Model, model: Model
		if props.Owned then
			model = Dummies:GetModelFromItemId(props.ItemId)
			local cf = props.RootArea
				:GetPivot()
				:ToWorldSpace(workspace.OriginalBase.RootArea:GetPivot():ToObjectSpace(model:GetPivot()))
			model:PivotTo(cf)
			model.Parent = workspace
			for i, itemId in ICDummies[props.ItemId].Unlocks or {} do
				props.Profile.Data.UnlockedItems[itemId] = true
			end
			props.triggerSetPlayer()
		else
			model = Dummies:GetModelFromItemId(props.ItemId)
			button = Dummies:GetButton()
			-- button.Part.Anchored = true
			local originalBoundingCF = model:GetBoundingBox()
			local boundingCFrame = props.RootArea:GetPivot():ToWorldSpace(
				workspace.OriginalBase.RootArea:GetPivot():ToObjectSpace(originalBoundingCF)
			)
			local cf = props.RootArea
				:GetPivot()
				:ToWorldSpace(workspace.OriginalBase.RootArea:GetPivot():ToObjectSpace(model:GetPivot()))
			button:PivotTo(cf)
			button.Parent = workspace;
			(button.PrimaryPart.BillboardGui.TextLabel :: TextLabel).Text = (props.DisplayName or props.ItemId)
				.. "-[$"
				.. Alyanum.new(props.Price):toString()
				.. "]"
			local touched = false
			button.PrimaryPart.Touched:Connect(function(part: Part)
				if part.Name ~= "HumanoidRootPart" and part.Parent:FindFirstChild("Humanoid") then
					return
				end

				if not props.BuyButton(props.ItemId) then
					return
				end

				if touched then
					return
				end
				touched = true

				-- task.spawn(function()
				-- 	local tempbutton = button
				-- 	button = nil
				-- 	local Animator: Animator = tempbutton.AnimationController.Animator
				-- 	local Animation: Animation = Animator.Animation
				-- 	local AnimTrack: AnimationTrack = Animator:LoadAnimation(Animation)
				-- 	AnimTrack:Play(0, 1, 10)
				-- 	AnimTrack.Ended:Wait()
				-- 	tempbutton:Destroy()
				-- end)

				local Debris = game:GetService("Debris")
				local pemitter = (function()
					local clone = workspace.ParticlePart:Clone()
					clone:PivotTo(cf)
					clone.Parent = workspace
					return clone
				end)()
				Debris:AddItem(pemitter, 3)

				--[[ Create temporary beam between model pivot and bounding box center]]
				local tempPart = Instance.new("Part")
				tempPart.Transparency = 1
				tempPart.Anchored = true
				tempPart.CanCollide = false
				tempPart.Size = Vector3.new(0.1, 0.1, 0.1)
				tempPart.Parent = workspace
				Debris:AddItem(tempPart, 3)

				local att0 = Instance.new("Attachment")
				att0.WorldPosition = cf.Position
				att0.Parent = tempPart

				local att1 = Instance.new("Attachment")
				att1.WorldPosition = boundingCFrame.Position
				att1.Parent = tempPart

				local beam = Instance.new("Beam")
				beam.Attachment0 = att0
				beam.Attachment1 = att1
				beam.Width0 = 1
				beam.Width1 = 1
				beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
				beam.FaceCamera = true
				beam.Parent = tempPart
				beam.Texture = "rbxassetid://136242854116857"
				beam.TextureSpeed = 0.4
				beam.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0.4),
					NumberSequenceKeypoint.new(1, 1),
				})

				warn(tempPart)
				game.ReplicatedStorage.Shared.Events.Ping:FireAllClients()

				task.wait(1 / 10)
				pemitter.ParticleEmitter:Emit()
			end)
		end
		return function()
			if model then
				model:Destroy()
			end
			if button then
				button:Destroy()
			end
		end
	end, { props.Owned })
	return e("Folder")
end


local function ItemRenderer(props: {
	Player: Player,
	Plot: Model,
})
	local profile = PlayerDataService:GetProfile(props.Player)
	if not profile then
		return
	end
	local cash, setCash = useState(profile.Data.Resources.Money)
	local playerData, setPlayerData = useState(profile.Data)
	local children = {}

	-- Persistent set of unowned unlocked items currently rendered
	local renderedUnownedSet = useRef({})

	local function BuyButton(ItemId: string): boolean
		local success = false
		local total = profile.Data.Resources.Money - ICDummies[ItemId].Price
		local pd = PlayerData.Collections[props.Player]
		if total >= 0 then
			profile.Data.Resources.Money = total
			setCash(total)
			pd:FireBEChanged()
			profile.Data.OwnedItems[ItemId] = true
			-- Remove from renderedUnownedSet so a new one can be added
			renderedUnownedSet.current[ItemId] = nil
			for i, unlockedItemId in ICDummies[ItemId].Unlocks or {} do
				profile.Data.UnlockedItems[unlockedItemId] = true
			end
			setPlayerData(function(prev)
				return table.clone(profile.Data)
			end)

			success = true
		else
			-- warn("Not enough")
		end
		warn(success)
		return success
	end

	local unownedCount = 0
	local function triggerSetPlayer()
		setPlayerData(function(prev)
			return table.clone(profile.Data)
		end)
	end
	for i, itemConfig in ipairs(ICDummies) do
		local unlocked = playerData.UnlockedItems[itemConfig.ItemId]
		if not unlocked then
			continue
		end

		local owned = playerData.OwnedItems[itemConfig.ItemId]
		if owned then
			-- Always render owned items
			children[itemConfig.ItemId] = e(Item, {
				key = itemConfig.ItemId,
				Owned = true,
				ItemId = itemConfig.ItemId,
				DisplayName = itemConfig.DisplayName,
				Price = itemConfig.Price,
				triggerSetPlayer = triggerSetPlayer,
				Profile = PlayerDataService:GetProfile(props.Player),
				RootArea = props.Plot.RootArea,
				BuyButton = BuyButton,
			})
		else
			-- Unowned, unlocked
			if renderedUnownedSet.current[itemConfig.ItemId] then
				-- Already rendered, keep rendering
				unownedCount += 1
				children[itemConfig.ItemId] = e(Item, {
					key = itemConfig.ItemId,
					Owned = false,
					ItemId = itemConfig.ItemId,
					DisplayName = itemConfig.DisplayName,
					Price = itemConfig.Price,
					triggerSetPlayer = triggerSetPlayer,
					Profile = PlayerDataService:GetProfile(props.Player),
					RootArea = props.Plot.RootArea,
					BuyButton = BuyButton,
				})
			elseif unownedCount < 5 then
				-- Not yet rendered, but we have quota
				renderedUnownedSet.current[itemConfig.ItemId] = true
				unownedCount += 1
				children[itemConfig.ItemId] = e(Item, {
					key = itemConfig.ItemId,
					Owned = false,
					ItemId = itemConfig.ItemId,
					DisplayName = itemConfig.DisplayName,
					Price = itemConfig.Price,
					triggerSetPlayer = triggerSetPlayer,
					Profile = PlayerDataService:GetProfile(props.Player),
					RootArea = props.Plot.RootArea,
					BuyButton = BuyButton,
				})
			end
			-- If not in set and quota full, skip rendering
		end

		local MoneyDisplayUpdate = game.ReplicatedStorage.Shared.Events:FindFirstChild("MoneyDisplayUpdate")
		if not MoneyDisplayUpdate then
			MoneyDisplayUpdate = Instance.new("RemoteEvent")
			MoneyDisplayUpdate.Name = "MoneyDisplayUpdate"
			MoneyDisplayUpdate.Parent = game.ReplicatedStorage.Shared.Events
		end
		-- Only send money/rate, not full PlayerData
		MoneyDisplayUpdate:FireClient(props.Player, profile.Data.Resources.Money, profile.Data.Resources.Rate or 0)
	end
	return e("Folder", {
		Name = "ItemRenderer",
	}, children)
end

-- MANAGES EVERY PLAYER'S ITEM RENDERER
local function ItemRendererApp(props)
	local renderers: { [Player]: { Player: Player, Plot: Model } }, setRenderers = useState({})
	local renderersRef = useRef({})

	-- Once Mounted
	useEffect(function()
		local playerSet: { [Player]: boolean } = {}

		local function createRenderer(player: Player)
			if playerSet[player] then
				return
			end
			playerSet[player] = true
			setRenderers(function(prev)
				local newRenderers = table.clone(prev)
				local Plot = getPlot()
				PlayerPlot[player] = Plot

				-- Set up character respawn
				local cSet = function()
					local char = player.Character or player.CharacterAdded:Wait()
					player.CharacterAdded:Connect(function(cmodel: Model)
						warn("ADDED", cmodel)
						setRenderers(function(prev)
							local clone = table.clone(prev)
							clone[player].Character = cmodel
							return clone
						end)
					end)
					setRenderers(function(prev)
						local clone = table.clone(prev)
						clone[player].Character = char
						return clone
					end)
					char:PivotTo(Plot.PrimaryPart:GetPivot() + Vector3.new(0, 10, 0))
				end
				task.spawn(cSet)

				newRenderers[player] = {
					Player = player,
					Plot = Plot,
				}
				return newRenderers
			end)
		end

		local function cleanupRenderer(player: Player)
			setRenderers(function(prev)
				local newRenderers = table.clone(prev)
				if newRenderers[player] then
					addPlot(newRenderers[player].Plot)
					newRenderers[player] = nil
				end
				return newRenderers
			end)
			playerSet[player] = false
		end

		-- on player added and removed
		local pAddedCon = game.Players.PlayerAdded:Connect(createRenderer)
		local pRemovedCon = game.Players.PlayerRemoving:Connect(cleanupRenderer)

		-- iterate Players in case player joined before the connection
		for i, Player: Player in game.Players:GetPlayers() do
			if playerSet[Player] then
				continue
			end
			createRenderer(Player)
		end

		return function()
			if pAddedCon then
				pAddedCon:Disconnect()
			end
			if pRemovedCon then
				pRemovedCon:Disconnect()
			end
		end
	end, {})

	useEffect(function()
		renderersRef.current = renderers
	end, { renderers })

	local children = {}

	for i, renderer in renderers do
		children[renderer.Player.Name .. "'s Renderer"] = e(ItemRenderer, {
			key = "renderer" .. renderer.Player.UserId,
			Player = renderer.Player,
			Plot = renderer.Plot,
		})
	end

	return e("Folder", {
		Name = "ItemRendererApp",
	}, children)
end

return ItemRendererApp
