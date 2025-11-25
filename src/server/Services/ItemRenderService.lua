local BadgeService = game:GetService("BadgeService")
local TweenService = game:GetService("TweenService")
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
local ICLookup = Dummies.ICLookup
local PDDummy = Dummies.PlayerData
local ProfileStore = require(game.ServerScriptService.Server.Services.ProfileStore)
local ti = TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut, -1, true)
type PlayerData = PlayerData.PlayerData
type Profile = ProfileStore.Profile<PlayerData>

local ItemRenderService = {}
ItemRenderService.Collections = {}

local function Item(props: {
	Owned: boolean,
	ItemId: string,
	Price: number,
	RootArea: Part,
	Player: Player,
	Profile: Profile,
	triggerSetPlayer: () -> nil,
	BuyButton: (ItemId: string) -> nil,
	SlotNum: Slot,
	Folder: Folder,
	isMountedRef: any,
})
	useEffect(function()
		local button: Model, model: Model
		local player = props.Player
		local tween
		if props.Owned then
			model = Dummies:GetModelFromItemId(props.ItemId)
			local cf = props.RootArea
				:GetPivot()
				:ToWorldSpace(workspace.OriginalBase.Value.RootArea:GetPivot():ToObjectSpace(model:GetPivot()))
			model:PivotTo(cf)
			if props.SlotNum then
				local highlight = Instance.new("Highlight", model)
				highlight.FillTransparency = 1
				highlight.OutlineColor = Color3.new(0.5, 0.5, 1)
				highlight.FillColor = Color3.new(1, 1, 1)
				highlight.DepthMode = Enum.HighlightDepthMode.Occluded

				tween = TweenService:Create(highlight, ti, {
					OutlineColor = Color3.new(0.5, 1, 0.5),
					FillTransparency = 0.8,
					FillColor = Color3.new(0.5, 0.5, 1),
				})
				tween:Play()

				model.Parent = props.Folder.ItemSlots
				model.Name = props.SlotNum
				local billboard = game.ReplicatedStorage.Shared.BillboardGui:Clone()
				billboard.Name = "ItemBillboard_" .. props.ItemId
				billboard.Parent = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
				-- Create an invisible anchored part at the bounding box center
				local boundingCF, boundingSize = model:GetBoundingBox()
				local billboardPart = Instance.new("Part")
				billboardPart.Name = "BillboardPart"
				billboardPart.Size = Vector3.new(0.1, 0.1, 0.1)
				billboardPart.Anchored = true
				billboardPart.CanCollide = false
				billboardPart.Transparency = 1
				billboardPart.Parent = model
				billboardPart:PivotTo(boundingCF)

				billboard.Parent = billboardPart
				if billboard:FindFirstChild("TextLabel") then
					billboard.TextLabel.Text = props.DisplayName or props.ItemId
				end
			else
				model.Parent = props.Folder
			end

			model:SetAttribute("UserId", player.UserId)

			local profile = PlayerDataService:GetProfile(player)
			local pdEvent = game.ReplicatedStorage:FindFirstChild("Shared")
				and game.ReplicatedStorage.Shared.Events:FindFirstChild("PlayerDataUpdated")
			if pdEvent and props.isMountedRef and props.isMountedRef.current then
				pdEvent:FireClient(player, profile.Data)
				warn("FIRED CLIENT")
			end
		else
			model = Dummies:GetModelFromItemId(props.ItemId)
			button = props.SlotNum and workspace:FindFirstChild("SlotButton").Value:Clone()
				or workspace:FindFirstChild("Button").Value:Clone()
			local originalBoundingCF = model:GetBoundingBox()
			local boundingCFrame = props.RootArea:GetPivot():ToWorldSpace(
				workspace.OriginalBase.Value.RootArea:GetPivot():ToObjectSpace(originalBoundingCF)
			)
			local cf = props.RootArea
				:GetPivot()
				:ToWorldSpace(workspace.OriginalBase.Value.RootArea:GetPivot():ToObjectSpace(model:GetPivot()))
			button:PivotTo(cf)
			button.Parent = props.Folder
			button.Name = "Button_" .. props.ItemId;

			(button.PrimaryPart.BillboardGui.TextLabel :: TextLabel).Text = (props.DisplayName or props.ItemId)
				.. "-[$"
				.. (props.Price < 1000 and props.Price or Alyanum.new(props.Price):toString())
				.. "]"
			local touched = false
			button.PrimaryPart.Touched:Connect(function(part: Part)
				local p = game:GetService("Players"):GetPlayerFromCharacter(part.Parent)
				if p ~= props.Player then
					warn(p, "is not", props.Player)
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
				beam.Texture = "rbxassetid://121071403345753"
				beam.TextureSpeed = 0.4
				beam.TextureMode = Enum.TextureMode.Static
				-- beam.Transparency = NumberSequence.new({
				-- 	NumberSequenceKeypoint.new(0, 1),
				-- 	NumberSequenceKeypoint.new(0.5, 0.4),
				-- 	NumberSequenceKeypoint.new(1, 1),
				-- })

				game.ReplicatedStorage.Shared.Events.Ping:FireClient(props.Player, props.SlotNum and "gen")

				task.wait(1 / 10)
				pemitter.ParticleEmitter:Emit()
			end)
		end
		return function()
			if
				ItemRenderService.Collections[props.Player]
				and type(ItemRenderService.Collections[props.Player]) == "table"
				and props.SlotNum
			then
				ItemRenderService.Collections[props.Player][props.SlotNum] = nil
			end
			if model then
				model:Destroy()
			end
			if button then
				button:Destroy()
			end
			if tween then
				tween:Cancel()
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
	local Folder: Folder = useState(function()
		local folder = Instance.new("Folder", workspace)
		folder.Name = props.Player.Name .. "ItemRenderer"

		local ItemSlotsFolder = Instance.new("Folder", folder)
		ItemSlotsFolder.Name = "ItemSlots"
		return folder
	end)
	local playerData, setPlayerData = useState(profile.Data)
	local children = {}
	local isMountedRef = useRef(false)

	-- Persistent set of unowned unlocked items currently rendered
	local renderedUnownedSet = useRef({})

	--cleanup
	useEffect(function()
		isMountedRef.current = true
		return function()
			isMountedRef.current = false
			if Folder then
				Folder:Destroy()
			end
		end
	end, {})

	local function BuyButton(ItemId: string): boolean
		local success = false
		local total = profile.Data.Resources.Money - ICDummies[ItemId].Price
		local pd = PlayerData.Collections[props.Player]
		if total >= 0 then
			profile.Data.Resources.Money = total
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
		return success
	end

	local unownedCount = 0
	local ItemSlots = {}
	local PlayerItemSlots = require(script.Parent.Parent.Classes.ItemSlots).Collections[props.Player]
	while not PlayerItemSlots do
		PlayerItemSlots = require(script.Parent.Parent.Classes.ItemSlots).Collections[props.Player]
		task.wait()
		warn("WAITING FOR ITEMSLOTS")
	end

	useEffect(function()
		local profile = PlayerDataService:GetProfile(props.Player)
		if profile and isMountedRef.current then
			-- Notify client of updated props.Player data if an event exists
			local pdEvent = game.ReplicatedStorage:FindFirstChild("Shared")
				and game.ReplicatedStorage.Shared.Events:FindFirstChild("PlayerDataUpdated")
			if pdEvent then
				pdEvent:FireClient(props.Player, profile.Data)
				warn("FIRED CLIENT")
			end
		end
	end, { playerData })

	useEffect(function()
		local needsUpdate = false
		-- Create a mutable copy to work with, to avoid mutating state directly
		local newUnlockedItems = table.clone(playerData.UnlockedItems)

		-- Loop through all owned items
		for ownedItemId, isOwned in pairs(playerData.OwnedItems) do
			if isOwned and ICDummies[ownedItemId] then
				-- For each owned item, check its unlock list from the config
				for _, unlockedItemId in ipairs(ICDummies[ownedItemId].Unlocks or {}) do
					-- If an item should be unlocked but isn't, mark it for update
					if not newUnlockedItems[unlockedItemId] then
						newUnlockedItems[unlockedItemId] = true
						needsUpdate = true
					end
				end
			end
		end

		-- If any new items were unlocked, trigger a SINGLE re-render with the updated data.
		if needsUpdate then
			-- Update the profile directly so data is saved
			profile.Data.UnlockedItems = newUnlockedItems
			-- Update the state to trigger the re-render
			setPlayerData(function(prev)
				local newPlayerData = table.clone(prev)
				newPlayerData.UnlockedItems = newUnlockedItems
				return newPlayerData
			end)
			warn("[ItemRenderer] Synced unlocks for " .. props.Player.Name)
		end
	end, { playerData.OwnedItems }) -- Dependency: This effect only re-runs if the OwnedItems table changes.

	local completed = false
	for i, itemConfig in ipairs(ICDummies) do
		local unlocked = playerData.UnlockedItems[itemConfig.ItemId]
		if not unlocked then
			continue
		end

		local owned = playerData.OwnedItems[itemConfig.ItemId]
		if owned then
			-- Always render owned items

			local SlotNum
			-- integrity of itemslots between two services
			if itemConfig.ItemSlot then
				if not profile.Data.ItemSlots["Slot" .. itemConfig.ItemSlot] then
					profile.Data.ItemSlots["Slot" .. itemConfig.ItemSlot] = "none"
				end
				ItemSlots["Slot" .. itemConfig.ItemSlot] = profile.Data.ItemSlots["Slot" .. itemConfig.ItemSlot]
				SlotNum = "Slot" .. itemConfig.ItemSlot
			end

			children[itemConfig.ItemId] = e(Item, {
				key = itemConfig.ItemId,
				Owned = true,
				ItemId = itemConfig.ItemId,
				Player = props.Player,
				DisplayName = itemConfig.DisplayName,
				Price = itemConfig.Price,
				-- triggerSetPlayer = triggerSetPlayer,
				Profile = PlayerDataService:GetProfile(props.Player),
				RootArea = props.Plot.RootArea,
				SlotNum = SlotNum,
				BuyButton = BuyButton,
				Folder = Folder,
				isMountedRef = isMountedRef,
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
					Player = props.Player,
					Price = itemConfig.Price,
					-- -- triggerSetPlayer = triggerSetPlayer,
					Profile = PlayerDataService:GetProfile(props.Player),
					RootArea = props.Plot.RootArea,
					BuyButton = BuyButton,
					Folder = Folder,
					SlotNum = itemConfig.ItemSlot and "Slot" .. itemConfig.ItemSlot,
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
					Player = props.Player,
					Price = itemConfig.Price,
					-- -- triggerSetPlayer = triggerSetPlayer,
					Profile = PlayerDataService:GetProfile(props.Player),
					RootArea = props.Plot.RootArea,
					BuyButton = BuyButton,
					Folder = Folder,
					SlotNum = itemConfig.ItemSlot and "Slot" .. itemConfig.ItemSlot,
					isMountedRef = isMountedRef,
				})
			end
			-- If not in set and quota full, skip rendering
		end
	end

	-- check for completion:
	task.spawn(function()
		profile.Data.StartTime = profile.Data.StartTime or tick()

		-- Don't run if the profile is not fully loaded
		if not profile or not profile.Data.OwnedItems then
			return
		end

		-- Check if the player has already been marked as completed
		if profile.Data.GameCompleted then
			return
		end

		if not ICDummies then
			return
		end

		if ICDummies and type(ICDummies) == "table" and #ICDummies < 1 then
			return
		end

		local playercompleted = true
		-- player always completed unless not own any of the current config
		for i, config in ICDummies do
			if not profile.Data.OwnedItems[config.ItemId] then
				playercompleted = false
				break
			end
		end
		if playercompleted then
			warn("✨✨✨PLAYER HAS COMPLETED THE GAME✨✨✨")
			BadgeService:AwardBadge(props.Player.UserId, 3687172302169394)
			profile.Data.GameCompleted = true
			profile.Data.CompletedMoney = profile.Data.CompletedMoney or profile.Data.Resources.Money
			profile.Data.CompletedTime = profile.Data.CompletedTime or tick()
			-- Fire remote event
			local GameCompleted = game.ReplicatedStorage.Shared.Events:FindFirstChild("GameCompleted")
			if GameCompleted then
				GameCompleted:FireClient(props.Player, profile.Data)
			end
		end
	end)

	local MoneyDisplayUpdate = game.ReplicatedStorage.Shared.Events:FindFirstChild("MoneyDisplayUpdate")
	if not MoneyDisplayUpdate then
		MoneyDisplayUpdate = Instance.new("RemoteEvent")
		MoneyDisplayUpdate.Name = "MoneyDisplayUpdate"
		MoneyDisplayUpdate.Parent = game.ReplicatedStorage.Shared.Events
	end
	if isMountedRef.current then
		MoneyDisplayUpdate:FireClient(
			props.Player,
			PlayerDataService:GetProfile(props.Player).Data.Resources.Money,
			PlayerDataService:GetProfile(props.Player).Data.Resources.Rate or 0
		)
		warn("FIRED CLIENT")
	end
	for slot, UID in PlayerDataService:GetProfile(props.Player).Data.ItemSlots do
		if not ItemSlots[slot] then
			PlayerDataService:GetProfile(props.Player).Data.ItemSlots[slot] = nil
		end
	end
	PlayerItemSlots.FireChangedEvent(PlayerDataService:GetProfile(props.Player).Data.ItemSlots)

	local OwnedItemsUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events:FindFirstChild("OwnedItemsUpdated")

	if not OwnedItemsUpdated then
		OwnedItemsUpdated = Instance.new("RemoteEvent")
		OwnedItemsUpdated.Name = "OwnedItemsUpdated"
		OwnedItemsUpdated.Parent = game.ReplicatedStorage.Shared.Events
	end
	-- warn(OwnedItemsUpdated)
	if isMountedRef.current then
		OwnedItemsUpdated:FireClient(props.Player, profile.Data.OwnedItems)
		warn("FIRED CLIENT")
	end

	return e("Folder", {
		Name = props.Player.Name .. "'s ItemRenderer",
	}, children)
end

-- MANAGES EVERY PLAYER'S ITEM RENDERER
local function ItemRendererApp(props)
	local renderers: { [Player]: { Player: Player, Plot: Model } }, setRenderers = useState({})
	local renderersRef = useRef({})
	local PlotService = require(game.ServerScriptService.Server.Services.PlotService)

	-- Once Mounted
	useEffect(function()
		local playerSet: { [Player]: boolean } = {}
		local conn

		local function createRenderer(player: Player)
			if playerSet[player] then
				return
			end
			playerSet[player] = true
			setRenderers(function(prev)
				local newRenderers = table.clone(prev)
				local Plot = PlotService.GetPlot(player)

				-- Set up character respawn
				local cSet = function()
					local char = player.Character or player.CharacterAdded:Wait()
					conn = player.CharacterAdded:Connect(function(cmodel: Model)
						warn("ADDED", cmodel)
						setRenderers(function(prev)
							local clone = table.clone(prev)
							clone[player].Character = cmodel
							return clone
						end)
						cmodel:PivotTo(Plot.PrimaryPart:GetPivot() + Vector3.new(0, 10, 0))
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
					PlotService.ReturnPlot(player)

					-- Gradual cleanup to prevent frame drops
					task.spawn(function()
						local rendererFolder = workspace:FindFirstChild(player.Name .. "ItemRenderer")
						if rendererFolder then
							local items = rendererFolder:GetDescendants()
							-- Destroy items in batches
							local batchSize = 10
							for i = 1, #items, batchSize do
								for j = i, math.min(i + batchSize - 1, #items) do
									if items[j] and items[j].Parent then
										items[j]:Destroy()
									end
								end
								task.wait() -- Yield between batches to spread the load
							end
							-- Finally destroy the folder itself
							if rendererFolder.Parent then
								rendererFolder:Destroy()
							end
						end
					end)

					newRenderers[player] = nil
				end
				return newRenderers
			end)
			playerSet[player] = false
		end

		function ItemRenderService.RestartPlayer(player: Player)
			task.spawn(function()
				-- Don't wait for cleanup to finish, let it happen in background
				cleanupRenderer(player)

				-- Start creating new renderer immediately
				task.wait(0.1) -- Small delay to let first batch of cleanup happen

				setRenderers(function(prev)
					local newRenderers = prev and table.clone(prev) or {}
					local Plot = PlotService.GetPlot(player)
					newRenderers[player] = {
						Player = player,
						Plot = Plot,
					}
					local char = player.Character or player.CharacterAdded:Wait()
					char:PivotTo(Plot.PrimaryPart:GetPivot() + Vector3.new(0, 10, 0))

					return newRenderers
				end)
			end)
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
			if conn then
				conn:Disconnect()
			end
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
		Name = "ItemRenderer App",
	}, children)
end

function ItemRenderService.initialize()
	local rootfolder = Instance.new("Folder", workspace)
	rootfolder.Name = "ItemRenderServiceRoot"

	local GetOwnedItems: RemoteFunction = game.ReplicatedStorage.Shared.Events:FindFirstChild("GetOwnedItems")
	if not GetOwnedItems then
		GetOwnedItems = Instance.new("RemoteFunction")
		GetOwnedItems.Name = "GetOwnedItems"
		GetOwnedItems.Parent = game.ReplicatedStorage.Shared.Events
	end

	GetOwnedItems.OnServerInvoke = function(player: Player)
		local profile = PlayerDataService:GetProfile(player)
		local start = tick()
		while not profile and tick() - start < 5 do
			task.wait(0.1)
			profile = PlayerDataService:GetProfile(player)
		end
		if profile then
			return profile.Data.OwnedItems
		end
		return {}
	end

	-- New: Get sanitized item configs for client
	local GetItemConfigs: RemoteFunction = game.ReplicatedStorage.Shared.Events:FindFirstChild("GetItemConfigs")
	if not GetItemConfigs then
		GetItemConfigs = Instance.new("RemoteFunction")
		GetItemConfigs.Name = "GetItemConfigs"
		GetItemConfigs.Parent = game.ReplicatedStorage.Shared.Events
	end

	GetItemConfigs.OnServerInvoke = function(player: Player)
		-- Return configs without Prefab references (client can't access ServerScriptService models)
		local sanitizedConfigs = {}
		for i, config in ipairs(ICDummies) do
			sanitizedConfigs[i] = {
				ItemId = config.ItemId,
				DisplayName = config.DisplayName,
				Price = config.Price,
				Unlocks = config.Unlocks,
				UnlockedBy = config.UnlockedBy,
				ItemSlot = config.ItemSlot,
			}
		end
		return sanitizedConfigs
	end

	local root = ReactRoblox.createRoot(rootfolder)
	root:render(e("Folder", {}, e(ItemRendererApp)))
end
type Slot = string
function ItemRenderService.GetPlayerItemSlotModels(player: Player, SlotNum: Slot)
	local model
	local start = tick()
	repeat
		local playerCollection = ItemRenderService.Collections[player]
		warn(ItemRenderService, PlayerDataService:GetProfile(player))
		if playerCollection then
			model = ItemRenderService.Collections[player][SlotNum]
		end
		task.wait(0.3)
		warn("Waiting for model", SlotNum, ("%.4f"):format(tick() - start))
	until model
	return model
end

return ItemRenderService
