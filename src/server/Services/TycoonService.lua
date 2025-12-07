local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps
type PlayerData = sharedtypes.PlayerData
type ItemConfig = sharedtypes.ItemConfig
type ItemSlots = sharedtypes.ItemSlots
type Slot = sharedtypes.Slot

local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useRef = React.useRef
local useEffect = React.useEffect
local useMemo = React.useMemo
local useState = React.useState

local itemConfigs: { ItemConfig } = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)

local FormatUtil = require(game.ReplicatedStorage.Shared.Utils.Format)
local rateColor = FormatUtil.rateColor
local FormatItemLabelText = FormatUtil.FormatItemLabelText

local TycoonService = {}
local ItemSlots = require(game.ServerScriptService.Server.Classes.ItemSlots)
local PlayerSession = require(game.ServerScriptService.Server.Classes.PlayerSession)
type PlayerSession = PlayerSession.PlayerSession
local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)
local PlotService = require(game.ServerScriptService.Server.Services.PlotService)
-- local Item = require(game.ServerScriptService.Server.Classes.Item)
local MultiplierService = require(game.ServerScriptService.Server.Services.MultiplierService)

--[[======================================================================================================================================================================================================]]

local function getItems(player: Player): { Item }?
	local profile = PlayerDataService:GetProfile(player)
	while not profile do
		warn("Is this it?")
		profile = PlayerDataService:GetProfile(player)
		task.wait()
	end
	local items = profile.Data.Items
	return items
end

--[[======================================================================================================================================================================================================]]

local function OwnedItem(props)
	useEffect(function()
		if not props.Item or props.Item.OwnerShipTriggeredGrowth then
			return
		end
		props.Item.OwnerShipTriggeredGrowth = true
		task.spawn(function()
			props.RunGrowth()
		end)
	end, {})
	return e("Folder")
end

local function TycoonItem(
	props: {
		ItemUID: string | "none",
		Player: Player,
		SlotNum: Slot,
		Item: Item?,
		Rate: number,
		PlayerSession: PlayerSession,
		Plot: Model, -- nah
		PlayerData: PlayerData,
	}
)
	local ref = useRef()
	local cloneRef = useRef()
	local slot: Part, setSlot = useState(nil)
	local connectionsRef = useRef()
	local profile = PlayerDataService:GetProfile(props.Player)

	-- mount on tycoon's slot model
	useEffect(function()
		local PlacePP, RemovePP
		--wrapped in a thread because somehow if this is waiting for ItemRenderService, this halts ItemRenderService, a deadlock
		local thread = task.spawn(function()
			local folder

			local maxRetries = 20
			local retries = 0

			while retries < maxRetries do
				local success, result = pcall(function()
					return workspace:FindFirstChild(props.Player.Name .. "ItemRenderer")
				end)
				if success and result then
					folder = result:FindFirstChild("ItemSlots")
					if folder then
						break
					end
				end
				retries += 1
				task.wait(1)
			end

			if not folder then
				error("Failed to find ItemSlots folder for player: " .. tostring(props.Player.Name))
			end

			local slotsModel: Model = folder:WaitForChild(props.SlotNum) --ItemRenderService.GetPlayerItemSlotModels(props.Player, props.SlotNum)

			local cf, s = slotsModel:GetBoundingBox()
			--slotsModel:FindFirstChildWhichIsA("BasePart", true)

			local slotPart = slotsModel:FindFirstChild("SlotPart")
				or (function()
					local part = Instance.new("Part")
					part:PivotTo(cf)
					part.Anchored = true
					part.CanCollide = false
					part.Size = s
					part.Transparency = 1
					part.Parent = slotsModel
					part.Name = "SlotPart"
					return part
				end)()

			setSlot(slotPart)

			PlacePP = Instance.new("ProximityPrompt", slotPart)
			PlacePP.HoldDuration = 0
			PlacePP.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
			PlacePP.ActionText = "Place Item"
			PlacePP.MaxActivationDistance = 5 + 0.2 * (s.Magnitude + 1)
			PlacePP.KeyboardKeyCode = Enum.KeyCode.F
			PlacePP.RequiresLineOfSight = false
			PlacePP.UIOffset = Vector2.new(-10 * s.Magnitude, 0)

			if props.ItemUID ~= "none" then
				RemovePP = Instance.new("ProximityPrompt", slotPart)
				RemovePP.HoldDuration = 0
				RemovePP.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
				RemovePP.ActionText = "Remove Item"
				RemovePP.MaxActivationDistance = 5 + 0.2 * (s.Magnitude + 1)
				RemovePP.KeyboardKeyCode = Enum.KeyCode.R
				RemovePP.RequiresLineOfSight = false
				RemovePP.UIOffset = Vector2.new(-10 * s.Magnitude, 80)
			end

			connectionsRef.current = {
				--cheap
				PlacePPConnection = PlacePP.Triggered:Connect(function(playerwhotriggerred)
					if playerwhotriggerred ~= props.Player then
						return
					end
					local PlaceItem: RemoteEvent = game.ReplicatedStorage.Shared.Events.PlaceItem
					PlaceItem:FireClient(playerwhotriggerred, props.SlotNum)
				end),
				--cheap
				RemovePPConnection = (function()
					return RemovePP
						and RemovePP.Triggered:Connect(function(playerwhotriggerred)
							if playerwhotriggerred ~= props.Player then
								return
							end
							-- local IS = props.playerSession.Profile.Data.ItemSlots
							-- IS[props.SlotNum] = "none"
							props.PlayerSession:SetItemSlot(props.SlotNum, "none")
							game.ReplicatedStorage.Shared.Events.ItemSlotsUpdate:FireClient(
								props.Player,
								props.PlayerSession.Profile.Data.ItemSlots
							)

							-- ItemSlots.FireChangedEvent(
							-- 	PlayerDataService:GetProfile(props.Player).Data.ItemSlots,
							-- 	props.Player
							-- )
						end)
				end)(),
			}

			-- rendering item model
			if props.ItemUID ~= "none" then
				local item = props.PlayerSession:GetItem(props.ItemUID)
				assert(item, "NO ITEM WITH UID " .. props.ItemUID .. " FOUND")
				local ok, itemModel = pcall(function()
					local model = game.ReplicatedStorage.Shared.Models:FindFirstChild(item.ItemId)
					assert(model, "NO ITEM MODEL WITH ID" .. (props.ItemId or "") .. " FOUND")
					return model
				end)

				if not ok then
					warn(itemModel)
					itemModel = game.ReplicatedStorage.Shared.Models:FindFirstChild("error")
				end

				local clone: Model = itemModel:Clone()

				local tlabel = slotPart
					and slotPart:FindFirstChild("SurfaceGui")
					and slotPart.SurfaceGui:FindFirstChild("TextLabel")
				if tlabel then
					tlabel.Text = FormatItemLabelText(item)
				else
					-- If not found, clone BillboardGui from ReplicatedStorage.Shared
					local billboardGui = game.ReplicatedStorage.Shared:FindFirstChild("BillboardGui")
					if billboardGui then
						local clonedBillboard = billboardGui:Clone()
						clonedBillboard.Parent = clone
						clonedBillboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
						local textLabel = clonedBillboard:FindFirstChild("TextLabel")

						-- comment this; only show unmultiplied rate; dont need this
						-- local multiplier = MultiplierService.GetFinalMultiplier(props.Player)
						-- local displayItem = table.clone(props.Item)
						-- -- print("Multiplier", multiplier)
						-- if multiplier > 1 then
						-- 	displayItem.Rate = displayItem.Rate * multiplier
						-- end

						if textLabel and textLabel:IsA("TextLabel") then
							-- warn("displayItem", displayItem)
							-- local labelText = FormatItemLabelText(displayItem, multiplier > 1)
							local labelText = FormatItemLabelText(props.Item)
							textLabel.Text = labelText
						end
					else
						warn("BillboardGui not found in ReplicatedStorage.Shared")
					end
				end

				-- clone.PrimaryPart.Anchored = true
				cloneRef.current = clone

				clone.Parent = workspace
				clone:PivotTo(slotPart:GetPivot() + Vector3.new(0, slotPart.Size.Y / 2, 0))
			end
		end)
		return function()
			if thread then
				task.cancel(thread)
			end
			for i, cref in connectionsRef.current or {} do
				cref:Disconnect()
			end
			if PlacePP then
				PlacePP:Destroy()
			end
			if RemovePP then
				RemovePP:Destroy()
			end
			connectionsRef.current = nil
			if cloneRef.current then
				cloneRef.current:Destroy()
				cloneRef.current = nil
			end
		end
	end, { props.ItemUID, props.SlotNum, profile.Data.Multipliers })

	useEffect(function()
		local model = cloneRef.current
		if not model then
			return
		end

		-- rendering textlabel
		if props.ItemUID ~= "none" then
			local tlabel = slot
				and (
					slot:FindFirstChild("SurfaceGui") and slot.SurfaceGui:FindFirstChild("TextLabel")
					or model:FindFirstChild("BillboardGui") and model.BillboardGui:FindFirstChild("TextLabel")
				)
			if not tlabel then
				warn("NO tlabel")
				return
			end

			-- local multiplier = MultiplierService.GetFinalMultiplier(props.Player)
			-- local displayItem = table.clone(props.Item)
			-- if multiplier > 1 then
			-- 	displayItem.Rate = displayItem.Rate * multiplier
			-- end

			if tlabel and tlabel:IsA("TextLabel") then
				local labelText = FormatItemLabelText(props.Item)
				tlabel.Text = labelText
			end
		end
		return function() end
	end, { props.ItemUID, props.SlotNum, props.Rate })

	return e("Model", {
		ref = ref,
		Name = "Item" .. props.ItemUID or "",
	})
end

--[[======================================================================================================================================================================================================]]

local Tycoon = function(props: TycoonProps)
	local playerSession: PlayerSession = props.PlayerSession
	local pd = playerSession.Profile.Data
	-- We treat these as immutable sources of truth for the render cycle
	local itemSlots = pd.ItemSlots
	local items = pd.Items
	local isMountedRef = useRef(false)

	-- Force Update mechanism (if you aren't using a binding/store wrapper)
	local version, setVersion = useState(0)

	-- 1. DATA PREPARATION (Memoized)
	-- Create a map of [SlotNum] -> ItemData.
	-- This prevents the "render empty then overwrite" mess.
	local slotMapping = useMemo(function()
		local mapping = {}
		-- We iterate the Slots first, because that defines the grid
		for slotNum, uid in pairs(itemSlots) do
			if uid and uid ~= "none" then
				local item = playerSession:GetItem(uid)
				-- Only map if the item actually exists
				if item then
					mapping[slotNum] = item
				end
			end
		end
		return mapping
	end, { itemSlots, items, version })

	-- 2. RATE CALCULATION (Memoized)
	-- Calculate rate separately from rendering children.
	local currentRate = useMemo(function()
		local rate = 0

		-- Add rate from placed items
		for _, item in pairs(slotMapping) do
			rate += (item.Rate or 0)
		end

		-- Furniture Logic
		local FurnitureService = require(game.ServerScriptService.Server.Services.FurnitureService)
		for FurnitureId, _ in pairs(pd.OwnedItems or {}) do
			if FurnitureService:GetConfig(FurnitureId) then
				rate += 1
			end
		end

		-- Minimum rate logic
		if rate < 1 then
			return 1
		end

		return rate
	end, { slotMapping, pd.OwnedItems, pd.Resources.Money, pd.Collector })

	-- 3. SIDE EFFECTS (Entry Logic)
	-- Handle "On Entry" effects here, NOT in the render loop.
	useEffect(function()
		for _, item in pairs(slotMapping) do
			if item and not item.Entered then
				local IC = itemConfigs[item.ItemId]
				if IC and IC.Entry and type(IC.Entry) == "function" then
					task.defer(function()
						-- Run your entry logic here
						IC.Entry(item, props.PlayerSession)
					end)
				end
				-- Note: Mutating this here is still technically a side effect
				-- Ideally 'Entered' should be part of the state, not a flag on the object
				item.Entered = true
			end
		end
	end, { slotMapping })

	-- 4. GROWTH LOGIC (Preserved from your code)
	-- I kept your generic growth ref logic, just cleaned up the source
	local gFRef = useRef({})
	local setGrowthFunctions = useState({}) -- If you need this state elsewhere

	useEffect(function()
		local gF = {}
		for _, item in pairs(slotMapping) do
			local IC = itemConfigs[item.ItemId]
			if IC and IC.Growth and type(IC.Growth) == "function" then
				gF[item.UID] = function()
					IC.Growth(item, props.PlayerSession)
				end
			end
		end
		gFRef.current = gF
	end, { slotMapping })

	local function RunGrowth()
		-- ... your debug string logic ...
		for _, fn in pairs(gFRef.current) do
			fn()
		end
	end

	-- 5. RENDERING
	local children = {}

	-- Render A: The Logical Items (OwnedItem)
	-- These are invisible logic handlers for every item owned
	for _, item in pairs(items or {}) do
		children["Logic_" .. item.UID] = e(OwnedItem, {
			key = "Logic_" .. item.UID,
			Item = item,
			UID = item.UID,
			RunGrowth = RunGrowth,
		})
	end

	-- Render B: The Visual Slots (TycoonItem)
	-- Iterate through the DEFINED SLOTS in data
	for slotNum, uid in pairs(itemSlots) do
		local itemData = slotMapping[slotNum]

		if itemData then
			-- CASE: Slot has a valid item
			children[slotNum] = e(TycoonItem, {
				key = slotNum,
				SlotNum = slotNum,
				Item = itemData,
				PlayerSession = playerSession,
				ItemUID = itemData.UID,
				Player = props.Player,
				Rate = itemData.Rate,
				Plot = props.Plot,
			})
		else
			-- CASE: Slot is empty (or item data was missing/broken)
			children[slotNum] = e(TycoonItem, {
				key = slotNum,
				SlotNum = slotNum,
				Item = nil, -- Explicitly nil
				PlayerSession = playerSession,
				ItemUID = "none",
				Player = props.Player,
			})
		end
	end

	-- connections
	useEffect(function()
		local PlaceItem: RemoteEvent = game.ReplicatedStorage.Shared.Events.PlaceItem
		local SellItem: RemoteEvent = game.ReplicatedStorage.Shared.Events:WaitForChild("SellItem")
		local connections = {
			playerSession.StateChanged:Connect(function()
				setVersion(function(prev)
					return prev + 1
				end)
			end),
			sellItemConnection = SellItem.OnServerEvent:Connect(function(player, selectedItemUID: string)
				-- only owner
				if player ~= props.Player then
					return
				end
				if not selectedItemUID then
					return
				end
				playerSession:SellItem(selectedItemUID)
			end),
			placeitemconnection = PlaceItem.OnServerEvent:Connect(function(player, slotNum, uid)
				-- only owner
				if player ~= props.Player then
					return
				end
				-- only request with uid
				if not uid then
					return
				end
				-- only item that's valid
				local itemFromUID = playerSession:GetItem(uid)
				if not itemFromUID then
					return
				end
				-- only one item amongst all tycoon's slot
				playerSession:SetItemSlot(slotNum, uid)

				game.ReplicatedStorage.Shared.Events.ItemSlotsUpdate:FireClient(
					props.Player,
					playerSession.Profile.Data.ItemSlots
				)
				game.ReplicatedStorage.Shared.Events:FindFirstChild("MoneyDisplayUpdate"):FireClient(
					props.Player,
					playerSession.Profile.Data.Resources.Money,
					playerSession.Profile.Data.Resources.Rate or 0
				)
			end),
		}

		return function()
			for i, c in connections do
				c:Disconnect()
			end
		end
	end, {})

	-- 	-- MONEY LOOP
	useEffect(function()
		local running = true
		local TweenService = game:GetService("TweenService")
		local Debris = game:GetService("Debris")
		local thread = task.spawn(function()
			while running do
				-- warn("ran")
				task.wait(1)
				if playerSession.Profile.Data.Resources.Rate >= 0 then
					-- Apply multipliers to the base rate
					local baseRate = playerSession.Profile.Data.Resources.Rate
					local finalMultiplier = MultiplierService.GetFinalMultiplier(props.Player, "Money")
					local finalRate = math.floor(baseRate * finalMultiplier)
					local sum = playerSession.Profile.Data.Collector + finalRate
					local textlabel = props.Plot
						and props.Plot.Collector
						and props.Plot.Collector:FindFirstChild("CollectDisplay") :: Model
						and props.Plot.Collector.CollectDisplay:FindFirstChild("SurfaceGui")
						and props.Plot.Collector.CollectDisplay.SurfaceGui:FindFirstChild("TextLabel")
					if textlabel and textlabel:IsA("TextLabel") then
						-- Display multiplier if active
						local multiplierText = finalMultiplier > 1 and string.format(" (x%.2f)", finalMultiplier) or ""
						textlabel.Text = "Money: "
							.. Alyanum.new(sum):toString()
							.. "\nRate: "
							.. Alyanum.new(finalRate):toString()
							.. multiplierText
					end
					playerSession.Profile.Data.Collector = sum

					-- Create floating money indicator
					if finalRate > 0 and props.Plot and props.Plot.Collector then
						local CollectDisplay = props.Plot.Collector:FindFirstChild("CollectDisplay")
						if CollectDisplay then
							local startPosition = CollectDisplay:GetPivot().Position

							-- Create invisible part
							local part = Instance.new("Part")
							part.Size = Vector3.new(1, 1, 1)
							part.Transparency = 1
							part.CanCollide = false
							part.Anchored = true
							part.Position = startPosition
							part.Parent = workspace

							-- Clone and setup BillboardGui
							local billboardTemplate = game.ReplicatedStorage.Shared:FindFirstChild("BillboardGui")
							if billboardTemplate then
								local billboard = billboardTemplate:Clone()
								billboard.Parent = part
								local textLabel = billboard:FindFirstChild("TextLabel")
								if textLabel and textLabel:IsA("TextLabel") then
									textLabel.Text = "+" .. Alyanum.new(finalRate):toString()

									-- Tween text transparency
									local textTweenInfo =
										TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
									local textGoal = { TextTransparency = 1 }
									local textTween = TweenService:Create(textLabel, textTweenInfo, textGoal)
									textTween:Play()
								end

								-- Tween upwards
								local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
								local goal = { Position = startPosition + Vector3.new(0, 5, 0) }
								local tween = TweenService:Create(part, tweenInfo, goal)
								tween:Play()
							end

							-- Clean up after 1 second
							Debris:AddItem(part, 1)
						end
					end
				end
			end
		end)
		local Wipe: RemoteEvent = game.ReplicatedStorage.Shared:WaitForChild("Events").Wipe

		local conn = Wipe.OnServerEvent:Connect(function()
			running = false
			if thread then
				task.cancel(thread)
			end
		end)
		return function()
			if thread then
				task.cancel(thread)
			end
			running = false
			if conn then
				conn:Disconnect()
			end
		end
	end, {}) -- empty deps, runs once

	-- display owner board on tycoon mount
	useEffect(function()
		isMountedRef.current = true
		local plot = props.Plot
		local player = props.Player
		if not plot or not player then
			return
		end

		local ownerBoard = plot:FindFirstChild("OwnerBoard", true)
		local CollectButton: Part = plot:FindFirstChild("CollectButton", true)
		if not ownerBoard or not ownerBoard:IsA("Part") then
			return
		end
		local BaseLightAtt: Attachment = game.ReplicatedStorage.Shared:WaitForChild("BaseLightAtt"):Clone()
		BaseLightAtt.Parent = plot.PrimaryPart
		-- Create SurfaceGui
		local surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Name = "OwnerSurfaceGui"
		surfaceGui.Adornee = ownerBoard
		surfaceGui.Face = Enum.NormalId.Front
		-- surfaceGui.AlwaysOnTop = true
		surfaceGui.Parent = ownerBoard

		-- Create ImageLabel
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Size = UDim2.new(1, 0, 1, 0)
		imageLabel.BackgroundTransparency = 1
		imageLabel.Parent = surfaceGui

		-- Create TextLabel
		local TextLabel = Instance.new("TextLabel")
		TextLabel.Size = UDim2.new(1, 0, 1, 0)
		TextLabel.BackgroundTransparency = 1
		TextLabel.Text = player.Name
		TextLabel.TextScaled = true
		-- TextLabel.TextSize = 100
		TextLabel.Parent = surfaceGui
		TextLabel.Font = Enum.Font.FredokaOne
		TextLabel.ZIndex = 3

		-- Get player thumbnail
		local Players = game:GetService("Players")
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size420x420
		local thumbUrl, _ = Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)
		imageLabel.Image = thumbUrl

		-- Handling player money collection
		local touchconn = CollectButton.Touched:Connect(function(part)
			local char = part:FindFirstAncestor(player.Name)
			if not char then
				return
			end
			local p = game.Players:GetPlayerFromCharacter(char)
			if not p and p ~= player then
				return
			end
			if playerSession.Profile.Data.Collector > 0 then
				game.ReplicatedStorage.Shared.Events.Ping:FireClient(props.Player, "cash")
			else
				return
			end
			playerSession.Profile.Data.Resources.Money += playerSession.Profile.Data.Collector
			playerSession.Profile.Data.Collector = 0
			-- Fire unreliable money/rate update for HUD display
			local MoneyDisplayUpdate = game.ReplicatedStorage.Shared.Events:FindFirstChild("MoneyDisplayUpdate")
			if not MoneyDisplayUpdate then
				MoneyDisplayUpdate = Instance.new("RemoteEvent")
				MoneyDisplayUpdate.Name = "MoneyDisplayUpdate"
				MoneyDisplayUpdate.Parent = game.ReplicatedStorage.Shared.Events
			end
			-- Only send money/rate, not full PlayerData
			MoneyDisplayUpdate:FireClient(
				props.Player,
				playerSession.Profile.Data.Resources.Money,
				playerSession.Profile.Data.Resources.Rate or 0
			)

			local finalMultiplier = MultiplierService.GetFinalMultiplier(props.Player, "Money")
			local finalRate = math.floor(playerSession.Profile.Data.Resources.Rate * finalMultiplier)
			local sum = playerSession.Profile.Data.Collector + finalRate
			local textlabel = props.Plot
				and props.Plot.Collector
				and props.Plot.Collector:FindFirstChild("CollectDisplay") :: Model
				and props.Plot.Collector.CollectDisplay:FindFirstChild("SurfaceGui")
				and props.Plot.Collector.CollectDisplay.SurfaceGui:FindFirstChild("TextLabel")

			local multiplierText = finalMultiplier > 1 and string.format(" (x%.2f)", finalMultiplier) or ""

			if textlabel and textlabel:IsA("TextLabel") then
				textlabel.Text = "Money: "
					.. Alyanum.new(playerSession.Profile.Data.Collector):toString()
					.. "\nRate: "
					.. Alyanum.new(finalRate):toString()
					.. multiplierText
			else
				warn("No textlabel")
			end
			local leaderstats = player:FindFirstChild("leaderstats")
			local Cash = leaderstats.Cash
			Cash.Value = Alyanum.new(playerSession.Profile.Data.Resources.Money):toString()
		end)

		return function()
			isMountedRef.current = false
			if touchconn then
				touchconn:Disconnect()
			end
			if BaseLightAtt then
				BaseLightAtt:Destroy()
			end
			if surfaceGui then
				surfaceGui:Destroy()
			end
			local textlabel = props.Plot
				and props.Plot.Collector
				and props.Plot.Collector:FindFirstChild("CollectDisplay") :: Model
				and props.Plot.Collector.CollectDisplay:FindFirstChild("SurfaceGui")
				and props.Plot.Collector.CollectDisplay.SurfaceGui:FindFirstChild("TextLabel")
			if textlabel and textlabel:IsA("TextLabel") then
				textlabel.Text = ""
			else
				warn("No textlabel")
			end
		end
	end, { props.Plot, props.Player })

	-- Update Rate Display Effect
	useEffect(function()
		playerSession.Profile.Data.Resources.Rate = currentRate
		local MoneyDisplayUpdate = game.ReplicatedStorage.Shared.Events:FindFirstChild("MoneyDisplayUpdate")
		if not MoneyDisplayUpdate then
			MoneyDisplayUpdate = Instance.new("RemoteEvent")
			MoneyDisplayUpdate.Name = "MoneyDisplayUpdate"
			MoneyDisplayUpdate.Parent = game.ReplicatedStorage.Shared.Events
		end
		if isMountedRef.current then
			MoneyDisplayUpdate:FireClient(
				props.Player,
				playerSession.Profile.Data.Resources.Money,
				playerSession.Profile.Data.Resources.Rate or 0
			)
		end
	end, { currentRate })

	return e("Folder", {
		Name = props.Player.Name .. "'s Tycoon",
	}, children)
end

--[[======================================================================================================================================================================================================]]

-- MANAGES ALL TYCOON
local function TycoonApp(props)
	local tycoons: { [Player]: TycoonProps }, setTycoons = useState({} :: { [Player]: TycoonProps })
	local tycoonsRef = useRef({})
	local isMountedRef = useRef(false)

	-- Once Mounted
	useEffect(function()
		isMountedRef.current = true
		local playerSet: { [Player]: boolean } = {}

		TycoonService.GetTycoonFromPlayer = Instance.new("BindableFunction")
		TycoonService.GetTycoonFromPlayer.Name = "GetTycoonFromPlayer"
		TycoonService.GetTycoonFromPlayer.OnInvoke = function(player)
			return tycoonsRef.current and tycoonsRef.current[player]
		end

		TycoonService.GetPlayerCollector = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
		TycoonService.GetPlayerCollector.Name = "GetPlayerCollector"
		TycoonService.GetPlayerCollector.OnServerInvoke = function(player)
			local tycoon = tycoonsRef.current and tycoonsRef.current[player]
			if not tycoon or not tycoon.Plot then
				return nil
			end
			local collector = tycoon.Plot:FindFirstChild("Collector", true)
			if collector then
				local collectButton = collector:FindFirstChild("CollectButton", true)
				return collectButton
			end
			return nil
		end

		local function createTycoon(playerSession: PlayerSession)
			local player = playerSession.Player
			if playerSet[player] then
				return
			end
			playerSet[player] = true
			setTycoons(function(prev: { [Player]: TycoonProps })
				warn("setting player", player, "'s tycoon ")

				local newTycoons = table.clone(prev)
				local Plot = PlotService.GetPlot(player)
				local playersItemSlots = playerSession.Profile.Data.ItemSlots :: ItemSlots?

				if not playersItemSlots then
					warn("Kicking player")
					player:Kick("Sorry failed to fetch player data")
					return newTycoons
				end
				warn("playersItemSlots", playersItemSlots)

				newTycoons[player] = {
					Player = player,
					Plot = Plot,
					PlayerSession = playerSession,
					ItemSlots = playersItemSlots,
					Items = getItems(player),
					Character = nil,
				}
				warn("newTycoons", newTycoons)
				return newTycoons
			end)
		end

		local function cleanupTycoon(playerSession: PlayerSession)
			local player = playerSession.Player
			setTycoons(function(prev: { TycoonProps })
				local newTycoons = table.clone(prev)
				if newTycoons[player] then
					PlotService.ReturnPlot(player)
					newTycoons[player] = nil
				end
				return newTycoons
			end)
			playerSet[player] = false
		end

		-- on player added and removed
		local connections = {
			pAddedCon = PlayerDataService.ProfileCreated:Connect(createTycoon),
			pRemovedCon = PlayerDataService.ProfileSessionEnded:Connect(cleanupTycoon),
		}

		-- iterate Players in case player joined before the connection
		for i, Player: Player in game.Players:GetPlayers() do
			if playerSet[Player] then
				continue
			end
			local session = PlayerDataService:GetSession(Player)
			createTycoon(session)
		end

		function TycoonService.RestartPlayer(playerSession: PlayerSession)
			task.spawn(function()
				local player = playerSession.Player
				cleanupTycoon(playerSession)
				task.delay(0.5, function()
					setTycoons(function(prev: TycoonProps)
						local newTycoons = prev and table.clone(prev) or {}
						local Plot = PlotService.GetPlot(player)

						local playersItemSlots = PlayerDataService:GetProfile(player).Data.ItemSlots :: ItemSlots?
						if not playersItemSlots then
							warn("Kicking player: failed to fetch playerdata")
							player:Kick("Sorry failed to fetch player data")
							return newTycoons
						end
						newTycoons[player] = {
							Player = player,
							Plot = Plot,
							PlayerSession = playerSession,
							ItemSlots = playersItemSlots,
							Items = getItems(player),
							Character = nil,
						}
						return newTycoons
					end)
				end)
			end)
		end

		return function()
			isMountedRef.current = false
			if TycoonService.GetTycoonFromPlayer then
				TycoonService.GetTycoonFromPlayer:Destroy()
			end
			if TycoonService.GetPlayerCollector then
				TycoonService.GetPlayerCollector:Destroy()
			end
			if TycoonService.RestartPlayer then
				TycoonService.RestartPlayer = nil
			end

			if connections then
				for i, connection in connections do
					connection:Disconnect()
				end
			end
		end
	end, {})

	useEffect(function()
		tycoonsRef.current = tycoons
		warn("TYCOONs", tycoons)
	end, { tycoons })

	local children = {}

	-- warn("tycoons", tycoons)
	for i, tycoon: TycoonProps in tycoons do
		children[tycoon.Player.Name .. "'s Tycoon"] = e(Tycoon, {
			key = "tycoon" .. tycoon.Player.UserId,
			Player = tycoon.Player,
			PlayerSession = tycoon.PlayerSession,
			Plot = tycoon.Plot,
			ItemSlots = tycoon.ItemSlots,
			Items = tycoon.Items,
			Character = tycoon.Character,
		})
	end

	return e("Folder", {
		Name = "Tycoon App",
	}, children)
end

--[[======================================================================================================================================================================================================]]

function TycoonService.initialize()
	if TycoonService.isInitialized then
		return
	end
	TycoonService.isInitialized = true
end

function TycoonService.start()
	local rootFolder = Instance.new("Folder", workspace)
	rootFolder.Name = "TycoonServiceRoot"
	TycoonService.Root = ReactRoblox.createRoot(rootFolder)
	TycoonService.Root:render(e(TycoonApp))
end

return TycoonService

-- local function Tycoon(props: TycoonProps)
-- 	local children = {}
-- 	local isMountedRef = useRef(false)

-- 	local playerSession: PlayerSession = props.PlayerSession
-- 	-- local profile = playerSession.Profile
-- 	warn("playerSession", playerSession)
-- 	local itemSlots: ItemSlots = playerSession.Profile.Data.ItemSlots
-- 	local items: { Item } = playerSession.Profile.Data.Items

-- 	local version, setVersion = React.useState(0) -- to trigger rerender and useEffect deps

-- 	local growthFunctions: { [string]: () -> nil? }, setGrowthFunctions = useState({})
-- 	local gFRef = useRef(growthFunctions)

-- 	-- display owner board on tycoon mount
-- 	useEffect(function()
-- 		isMountedRef.current = true
-- 		local plot = props.Plot
-- 		local player = props.Player
-- 		if not plot or not player then
-- 			return
-- 		end

-- 		local ownerBoard = plot:FindFirstChild("OwnerBoard", true)
-- 		local CollectButton: Part = plot:FindFirstChild("CollectButton", true)
-- 		if not ownerBoard or not ownerBoard:IsA("Part") then
-- 			return
-- 		end
-- 		local BaseLightAtt: Attachment = game.ReplicatedStorage.Shared:WaitForChild("BaseLightAtt"):Clone()
-- 		BaseLightAtt.Parent = plot.PrimaryPart
-- 		-- Create SurfaceGui
-- 		local surfaceGui = Instance.new("SurfaceGui")
-- 		surfaceGui.Name = "OwnerSurfaceGui"
-- 		surfaceGui.Adornee = ownerBoard
-- 		surfaceGui.Face = Enum.NormalId.Front
-- 		-- surfaceGui.AlwaysOnTop = true
-- 		surfaceGui.Parent = ownerBoard

-- 		-- Create ImageLabel
-- 		local imageLabel = Instance.new("ImageLabel")
-- 		imageLabel.Size = UDim2.new(1, 0, 1, 0)
-- 		imageLabel.BackgroundTransparency = 1
-- 		imageLabel.Parent = surfaceGui

-- 		-- Create TextLabel
-- 		local TextLabel = Instance.new("TextLabel")
-- 		TextLabel.Size = UDim2.new(1, 0, 1, 0)
-- 		TextLabel.BackgroundTransparency = 1
-- 		TextLabel.Text = player.Name
-- 		TextLabel.TextScaled = true
-- 		-- TextLabel.TextSize = 100
-- 		TextLabel.Parent = surfaceGui
-- 		TextLabel.Font = Enum.Font.FredokaOne
-- 		TextLabel.ZIndex = 3

-- 		-- Get player thumbnail
-- 		local Players = game:GetService("Players")
-- 		local thumbType = Enum.ThumbnailType.HeadShot
-- 		local thumbSize = Enum.ThumbnailSize.Size420x420
-- 		local thumbUrl, _ = Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)
-- 		imageLabel.Image = thumbUrl

-- 		-- Handling player money collection
-- 		local touchconn = CollectButton.Touched:Connect(function(part)
-- 			local char = part:FindFirstAncestor(player.Name)
-- 			if not char then
-- 				return
-- 			end
-- 			local p = game.Players:GetPlayerFromCharacter(char)
-- 			if not p and p ~= player then
-- 				return
-- 			end
-- 			if playerSession.Profile.Data.Collector > 0 then
-- 				game.ReplicatedStorage.Shared.Events.Ping:FireClient(props.Player, "cash")
-- 			else
-- 				return
-- 			end
-- 			playerSession.Profile.Data.Resources.Money += playerSession.Profile.Data.Collector
-- 			playerSession.Profile.Data.Collector = 0
-- 			-- Fire unreliable money/rate update for HUD display
-- 			local MoneyDisplayUpdate = game.ReplicatedStorage.Shared.Events:FindFirstChild("MoneyDisplayUpdate")
-- 			if not MoneyDisplayUpdate then
-- 				MoneyDisplayUpdate = Instance.new("RemoteEvent")
-- 				MoneyDisplayUpdate.Name = "MoneyDisplayUpdate"
-- 				MoneyDisplayUpdate.Parent = game.ReplicatedStorage.Shared.Events
-- 			end
-- 			-- Only send money/rate, not full PlayerData
-- 			MoneyDisplayUpdate:FireClient(
-- 				props.Player,
-- 				playerSession.Profile.Data.Resources.Money,
-- 				playerSession.Profile.Data.Resources.Rate or 0
-- 			)

-- 			local finalMultiplier = MultiplierService.GetFinalMultiplier(props.Player, "Money")
-- 			local finalRate = math.floor(playerSession.Profile.Data.Resources.Rate * finalMultiplier)
-- 			local sum = playerSession.Profile.Data.Collector + finalRate
-- 			local textlabel = props.Plot
-- 				and props.Plot.Collector
-- 				and props.Plot.Collector:FindFirstChild("CollectDisplay") :: Model
-- 				and props.Plot.Collector.CollectDisplay:FindFirstChild("SurfaceGui")
-- 				and props.Plot.Collector.CollectDisplay.SurfaceGui:FindFirstChild("TextLabel")

-- 			local multiplierText = finalMultiplier > 1 and string.format(" (x%.2f)", finalMultiplier) or ""

-- 			if textlabel and textlabel:IsA("TextLabel") then
-- 				textlabel.Text = "Money: "
-- 					.. Alyanum.new(playerSession.Profile.Data.Collector):toString()
-- 					.. "\nRate: "
-- 					.. Alyanum.new(finalRate):toString()
-- 					.. multiplierText
-- 			else
-- 				warn("No textlabel")
-- 			end
-- 			local leaderstats = player:FindFirstChild("leaderstats")
-- 			local Cash = leaderstats.Cash
-- 			Cash.Value = Alyanum.new(playerSession.Profile.Data.Resources.Money):toString()
-- 		end)

-- 		return function()
-- 			isMountedRef.current = false
-- 			if touchconn then
-- 				touchconn:Disconnect()
-- 			end
-- 			if BaseLightAtt then
-- 				BaseLightAtt:Destroy()
-- 			end
-- 			if surfaceGui then
-- 				surfaceGui:Destroy()
-- 			end
-- 			local textlabel = props.Plot
-- 				and props.Plot.Collector
-- 				and props.Plot.Collector:FindFirstChild("CollectDisplay") :: Model
-- 				and props.Plot.Collector.CollectDisplay:FindFirstChild("SurfaceGui")
-- 				and props.Plot.Collector.CollectDisplay.SurfaceGui:FindFirstChild("TextLabel")
-- 			if textlabel and textlabel:IsA("TextLabel") then
-- 				textlabel.Text = ""
-- 			else
-- 				warn("No textlabel")
-- 			end
-- 		end
-- 	end, { props.Plot, props.Player })

-- 	-- once mount, connect to events
-- 	useEffect(function()
-- 		local PlaceItem: RemoteEvent = game.ReplicatedStorage.Shared.Events.PlaceItem
-- 		local SellItem: RemoteEvent = game.ReplicatedStorage.Shared.Events:WaitForChild("SellItem")
-- 		local connections = {
-- 			playerSession.StateChanged:Connect(function()
-- 				setVersion(function(prev)
-- 					return prev + 1
-- 				end)
-- 			end),
-- 			sellItemConnection = SellItem.OnServerEvent:Connect(function(player, selectedItemUID: string)
-- 				-- only owner
-- 				if player ~= props.Player then
-- 					return
-- 				end
-- 				if not selectedItemUID then
-- 					return
-- 				end
-- 				playerSession:SellItem(selectedItemUID)
-- 			end),
-- 			placeitemconnection = PlaceItem.OnServerEvent:Connect(function(player, slotNum, uid)
-- 				print("✌️✌️✌️", player, slotNum, uid)
-- 				-- only owner
-- 				if player ~= props.Player then
-- 					print("Not player,✌️✌️✌️")
-- 					return
-- 				end
-- 				-- only request with uid
-- 				if not uid then
-- 					warn("✌️✌️✌️ no uid")
-- 					return
-- 				end
-- 				-- only item that's valid
-- 				local itemFromUID = playerSession:GetItem(uid)
-- 				if not itemFromUID then
-- 					warn("✌️✌️✌️ not valid item")
-- 					return
-- 				end
-- 				-- only one item amongst all tycoon's slot
-- 				playerSession:SetItemSlot(slotNum, uid)

-- 				warn("Updated")
-- 				game.ReplicatedStorage.Shared.Events.ItemSlotsUpdate:FireClient(props.Player, playerSession.ItemSlots)
-- 				game.ReplicatedStorage.Shared.Events
-- 					:FindFirstChild("MoneyDisplayUpdate")
-- 					:FireClient(
-- 						props.Player,
-- 						playerSession.Profile.Data.Resources.Money,
-- 						playerSession.Profile.Data.Resources.Rate or 0
-- 					)
-- 			end),
-- 		}

-- 		return function()
-- 			for i, c in connections do
-- 				c:Disconnect()
-- 			end
-- 		end
-- 	end, {})

-- 	local placed: { [Slot]: string } = {}
-- 	local placedItems: { [string]: Item } = {}

-- 	local pd = playerSession.Profile.Data
-- 	-- RENDERING EMPTY ITEMSLOTS and storing placeditems
-- 	-- TODO this logic is ass, refactor later

-- 	for slotNum: Slot, ItemUID: string in playerSession.Profile.Data.ItemSlots do
-- 		placed[ItemUID] = slotNum
-- 		if ItemUID ~= "none" then
-- 			local item = pd and playerSession:GetItem(ItemUID)
-- 			-- check if item is actually exist there. If there is, it will be rendered later.
-- 			-- if itemuid actually leads to no where (deleted, sold) then render empty
-- 			if item then
-- 				-- if item exist, then leave it to next to render.
-- 				continue
-- 			else
-- 				pd.ItemSlots[slotNum] = "none"
-- 				if isMountedRef.current then
-- 					game.ReplicatedStorage.Shared.Events.ItemSlotsUpdate:FireClient(props.Player, pd.ItemSlots)
-- 				end
-- 			end
-- 		end

-- 		children[slotNum] = e(TycoonItem, {
-- 			key = slotNum,
-- 			SlotNum = slotNum,
-- 			Item = nil,
-- 			PlayerSession = playerSession,
-- 			ItemUID = "none",
-- 			Player = props.Player,
-- 		})
-- 	end

-- 	-- RENDERING ITEMS
-- 	local function RunGrowth()
-- 		local s = "running Growth functions:\n"
-- 		for uid, fn in gFRef.current do
-- 			s ..= uid .. ": " .. tostring(fn) .. "\n"
-- 			fn()
-- 		end
-- 	end
-- 	local rate = 0

-- 	for i, item: Item in items or {} do
-- 		-- a new OwnedItem will run growth
-- 		children[item.UID] = e(OwnedItem, {
-- 			key = item.UID,
-- 			Item = item,
-- 			UID = item.UID,
-- 			RunGrowth = RunGrowth,
-- 		})

-- 		if placed[item.UID] then
-- 			placedItems[item.UID] = item
-- 			local slotNum = placed[item.UID]
-- 			rate += item.Rate
-- 			children[slotNum] = e(TycoonItem, {
-- 				key = slotNum,
-- 				SlotNum = slotNum,
-- 				Item = item,
-- 				PlayerSession = playerSession,
-- 				ItemUID = item.UID,
-- 				Player = playerSession.Player,
-- 				Rate = item.Rate,
-- 				Plot = props.Plot,
-- 			})

-- 			-- running entry item effect
-- 			local IC = itemConfigs[item.ItemId]
-- 			if not IC then
-- 				continue
-- 			end

-- 			if item.Entered then -- only unEntered need to run
-- 				continue
-- 			end
-- 			if IC.Entry and type(IC.Entry) == "function" then
-- 				task.defer(function()
-- 					--[[
-- 					 MASSIVE TODO:
-- 					 	REFACTOR EFFECTS IN ITEMCONFIGS. PASS IN (item, playerSession) INSTEAD
-- 					 ]]
-- 					-- IC.Entry(item, props.Player)
-- 					-- item.Entered = true
-- 					-- may cause the Entered guard clause to not
-- 					-- detect since this is a task.defered function
-- 					-- so set outside
-- 				end)
-- 			end
-- 			item.Entered = true
-- 			continue
-- 		end
-- 	end

-- 	-- Furniture counts
-- 	local FurnitureService = require(game.ServerScriptService.Server.Services.FurnitureService)
-- 	for FurnitureId, v in playerSession.Profile.Data.OwnedItems do
-- 		if FurnitureService:GetConfig(FurnitureId) then
-- 			rate += 1
-- 		end
-- 	end

-- 	rate = (rate < 1 and (playerSession.Profile.Data.Resources.Money < 200 and playerSession.Profile.Data.Collector < 200)) and 200
-- 		or rate

-- 	-- update rate display
-- 	useEffect(function()
-- 		playerSession.Profile.Data.Resources.Rate = rate
-- 		local MoneyDisplayUpdate = game.ReplicatedStorage.Shared.Events:FindFirstChild("MoneyDisplayUpdate")
-- 		if not MoneyDisplayUpdate then
-- 			MoneyDisplayUpdate = Instance.new("RemoteEvent")
-- 			MoneyDisplayUpdate.Name = "MoneyDisplayUpdate"
-- 			MoneyDisplayUpdate.Parent = game.ReplicatedStorage.Shared.Events
-- 		end
-- 		if isMountedRef.current then
-- 			MoneyDisplayUpdate:FireClient(
-- 				props.Player,
-- 				playerSession.Profile.Data.Resources.Money,
-- 				playerSession.Profile.Data.Resources.Rate or 0
-- 			)
-- 		end
-- 	end, { rate })
-- 	local piref = useRef()

-- 	-- update growth functions
-- 	useEffect(function()
-- 		piref.current = placedItems
-- 		local gF: { [string]: () -> nil? } = {}
-- 		for uid, item in placedItems do
-- 			local IC = itemConfigs[item.ItemId]
-- 			if not IC then
-- 				continue
-- 			end
-- 			if not IC.Growth or type(IC.Growth) ~= "function" then
-- 				continue
-- 			end
-- 			gF[uid] = function()
-- 				--[[
-- 				MASSIVE TODO:
-- 				REFACTOR GROWTH TO TAKE IN PLAYERSESSION
-- 				]]
-- 				-- IC.Growth(pd:GetItemFromUID(item.UID), props.Player)
-- 			end
-- 		end
-- 		gFRef.current = gF
-- 		setGrowthFunctions(gF)
-- 	end, { items, itemSlots })

-- 	-- MONEY LOOP
-- 	useEffect(function()
-- 		local running = true
-- 		local TweenService = game:GetService("TweenService")
-- 		local Debris = game:GetService("Debris")
-- 		local thread = task.spawn(function()
-- 			while running do
-- 				-- warn("ran")
-- 				task.wait(1)
-- 				if playerSession.Profile.Data.Resources.Rate >= 0 then
-- 					-- Apply multipliers to the base rate
-- 					local baseRate = playerSession.Profile.Data.Resources.Rate
-- 					local finalMultiplier = MultiplierService.GetFinalMultiplier(props.Player, "Money")
-- 					local finalRate = math.floor(baseRate * finalMultiplier)
-- 					local sum = playerSession.Profile.Data.Collector + finalRate
-- 					local textlabel = props.Plot
-- 						and props.Plot.Collector
-- 						and props.Plot.Collector:FindFirstChild("CollectDisplay") :: Model
-- 						and props.Plot.Collector.CollectDisplay:FindFirstChild("SurfaceGui")
-- 						and props.Plot.Collector.CollectDisplay.SurfaceGui:FindFirstChild("TextLabel")
-- 					if textlabel and textlabel:IsA("TextLabel") then
-- 						-- Display multiplier if active
-- 						local multiplierText = finalMultiplier > 1 and string.format(" (x%.2f)", finalMultiplier) or ""
-- 						textlabel.Text = "Money: "
-- 							.. Alyanum.new(sum):toString()
-- 							.. "\nRate: "
-- 							.. Alyanum.new(finalRate):toString()
-- 							.. multiplierText
-- 					end
-- 					playerSession.Profile.Data.Collector = sum

-- 					-- Create floating money indicator
-- 					if finalRate > 0 and props.Plot and props.Plot.Collector then
-- 						local CollectDisplay = props.Plot.Collector:FindFirstChild("CollectDisplay")
-- 						if CollectDisplay then
-- 							local startPosition = CollectDisplay:GetPivot().Position

-- 							-- Create invisible part
-- 							local part = Instance.new("Part")
-- 							part.Size = Vector3.new(1, 1, 1)
-- 							part.Transparency = 1
-- 							part.CanCollide = false
-- 							part.Anchored = true
-- 							part.Position = startPosition
-- 							part.Parent = workspace

-- 							-- Clone and setup BillboardGui
-- 							local billboardTemplate = game.ReplicatedStorage.Shared:FindFirstChild("BillboardGui")
-- 							if billboardTemplate then
-- 								local billboard = billboardTemplate:Clone()
-- 								billboard.Parent = part
-- 								local textLabel = billboard:FindFirstChild("TextLabel")
-- 								if textLabel and textLabel:IsA("TextLabel") then
-- 									textLabel.Text = "+" .. Alyanum.new(finalRate):toString()

-- 									-- Tween text transparency
-- 									local textTweenInfo =
-- 										TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
-- 									local textGoal = { TextTransparency = 1 }
-- 									local textTween = TweenService:Create(textLabel, textTweenInfo, textGoal)
-- 									textTween:Play()
-- 								end

-- 								-- Tween upwards
-- 								local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
-- 								local goal = { Position = startPosition + Vector3.new(0, 5, 0) }
-- 								local tween = TweenService:Create(part, tweenInfo, goal)
-- 								tween:Play()
-- 							end

-- 							-- Clean up after 1 second
-- 							Debris:AddItem(part, 1)
-- 						end
-- 					end
-- 				end
-- 			end
-- 		end)
-- 		local Wipe: RemoteEvent = game.ReplicatedStorage.Shared:WaitForChild("Events").Wipe

-- 		local conn = Wipe.OnServerEvent:Connect(function()
-- 			running = false
-- 			if thread then
-- 				task.cancel(thread)
-- 			end
-- 		end)
-- 		return function()
-- 			if thread then
-- 				task.cancel(thread)
-- 			end
-- 			running = false
-- 			if conn then
-- 				conn:Disconnect()
-- 			end
-- 		end
-- 	end, {}) -- empty deps, runs once
-- 	-- warn("props.Items, items", props.Items, items)
-- 	return e("Folder", {
-- 		Name = props.Player.Name .. "'s Tycoon",
-- 	}, children)
-- end
