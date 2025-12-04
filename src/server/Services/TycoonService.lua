local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps
type PlayerData = sharedtypes.PlayerData
type ItemConfig = sharedtypes.ItemConfig
type ItemSlots = sharedtypes.ItemSlots
type Slot = sharedtypes.Slot

local ContentProvider = game:GetService("ContentProvider")
local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useRef = React.useRef
local useEffect = React.useEffect
local useState = React.useState

local itemConfigs: { ItemConfig } = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)

local FormatUtil = require(game.ReplicatedStorage.Shared.Utils.Format)
local rateColor = FormatUtil.rateColor
local FormatItemLabelText = FormatUtil.FormatItemLabelText

local TycoonService = {}
local ItemSlots = require(game.ServerScriptService.Server.Classes.ItemSlots)
local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)
local PlotService = require(game.ServerScriptService.Server.Services.PlotService)
local Item = require(game.ServerScriptService.Server.Classes.Item)
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
local function getItemSlots(player: Player): ItemSlots?
	local start = tick()

	while not PlayerDataService:GetProfile(player).Data do
		-- warn("waiting for PlayerDataService:GetProfile(player).Data", player)
		task.wait(0.1)
		local elapsed = tick() - start
		if elapsed >= 10 then
			break
		end
	end

	if not PlayerDataService:GetProfile(player).Data then -- if failed to fetch playerdata, returns nil
		warn("Player data fetch time out")
		return nil
	end

	local itemSlots = PlayerDataService:GetProfile(player).Data.ItemSlots
	return itemSlots
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
		Plot: Model, -- nah
		PlayerData: PlayerData,
	}
)
	local ref = useRef()
	local cloneRef = useRef()
	local slot: Part, setSlot = useState(nil)
	local pd = PlayerData.Collections[props.Player]
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

			local PlaceItem: RemoteEvent = game.ReplicatedStorage.Shared.Events.PlaceItem
			connectionsRef.current = {
				--cheap
				PlacePPConnection = PlacePP.Triggered:Connect(function(playerwhotriggerred)
					if playerwhotriggerred ~= props.Player then
						return
					end
					PlaceItem:FireClient(playerwhotriggerred, props.SlotNum)
				end),
				--cheap
				RemovePPConnection = (function()
					return RemovePP
						and RemovePP.Triggered:Connect(function(playerwhotriggerred)
							if playerwhotriggerred ~= props.Player then
								return
							end
							local IS = PlayerDataService:GetProfile(props.Player).Data.ItemSlots
							IS[props.SlotNum] = "none"
							ItemSlots.FireChangedEvent(
								PlayerDataService:GetProfile(props.Player).Data.ItemSlots,
								props.Player
							)
						end)
				end)(),
				--cheap
				placeitemconnection = PlaceItem.OnServerEvent:Connect(function(player, slotNum, uid)
					print("✌️✌️✌️", player, slotNum, uid)
					-- only owner
					if player ~= props.Player then
						-- print("Not player,✌️✌️✌️")
						return
					end
					-- only on slot which was fired from
					if slotNum ~= props.SlotNum then
						-- print("✌️✌️✌️ not slot")
						return
					else
					end
					-- only request with uid
					if not uid then
						warn("✌️✌️✌️ no uid")
						return
					end
					-- only item that's valid
					local itemFromUID = pd:GetItemFromUID(uid, props.Player)
					if not itemFromUID then
						warn("✌️✌️✌️ not valid item")
						return
					end
					-- only one item amongst all tycoon's slot
					local PIS = PlayerDataService:GetProfile(props.Player).Data.ItemSlots
					for sn, id in PIS do
						if id == uid then
							PIS[sn] = "none"
						end
						if sn == slotNum then
							PIS[sn] = uid
						end
					end
					local IS = require(game.ServerScriptService.Server.Classes.ItemSlots)

					warn("✌️✌️✌️", PlayerDataService:GetProfile(props.Player).Data.ItemSlots)
					IS.FireChangedEvent(PlayerDataService:GetProfile(props.Player).Data.ItemSlots, props.Player)

					game.ReplicatedStorage.Shared.Events:FindFirstChild("MoneyDisplayUpdate"):FireClient(
						props.Player,
						PlayerDataService:GetProfile(props.Player).Data.Resources.Money,
						PlayerDataService:GetProfile(props.Player).Data.Resources.Rate or 0
					)
				end),
			}

			-- rendering item model
			if props.ItemUID ~= "none" then
				local item = pd.GetItemFromUID(PlayerDataService:GetProfile(props.Player).Data, props.ItemUID)
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

local function Tycoon(props: TycoonProps)
	local children = {}
	-- local money, setMoney = useState(PlayerData.Collections[props.Player].Resources.Money)
	local resourcesRef = useRef(PlayerData.Collections[props.Player].Resources)
	local characterRef = useRef()
	local isMountedRef = useRef(false)

	local playerData: ItemSlots, setPlayerData = useState(PlayerDataService:GetProfile(props.Player))
	local itemSlots: ItemSlots, setItemSlots = useState(props.ItemSlots)
	local items: { Item }, setItems = useState(props.Items)
	local growthFunctions: { [string]: () -> nil? }, setGrowthFunctions = useState({})
	local gFRef = useRef(growthFunctions)

	-- useEffect(function()
	-- 	warn("#items", items)
	-- end, items)

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
			local profile = PlayerDataService:GetProfile(player)
			if not profile then
				return
			end
			if profile.Data.Collector > 0 then
				game.ReplicatedStorage.Shared.Events.Ping:FireClient(props.Player, "cash")
			else
				return
			end
			profile.Data.Resources.Money += profile.Data.Collector
			profile.Data.Collector = 0
			-- Fire unreliable money/rate update for HUD display
			local MoneyDisplayUpdate = game.ReplicatedStorage.Shared.Events:FindFirstChild("MoneyDisplayUpdate")
			if not MoneyDisplayUpdate then
				MoneyDisplayUpdate = Instance.new("RemoteEvent")
				MoneyDisplayUpdate.Name = "MoneyDisplayUpdate"
				MoneyDisplayUpdate.Parent = game.ReplicatedStorage.Shared.Events
			end
			-- Only send money/rate, not full PlayerData
			MoneyDisplayUpdate:FireClient(props.Player, profile.Data.Resources.Money, resourcesRef.current.Rate or 0)

			local finalMultiplier = MultiplierService.GetFinalMultiplier(props.Player, "Money")
			local finalRate = math.floor(resourcesRef.current.Rate * finalMultiplier)
			local sum = profile.Data.Collector + finalRate
			local textlabel = props.Plot
				and props.Plot.Collector
				and props.Plot.Collector:FindFirstChild("CollectDisplay") :: Model
				and props.Plot.Collector.CollectDisplay:FindFirstChild("SurfaceGui")
				and props.Plot.Collector.CollectDisplay.SurfaceGui:FindFirstChild("TextLabel")

			local multiplierText = finalMultiplier > 1 and string.format(" (x%.1f)", finalMultiplier) or ""

			if textlabel and textlabel:IsA("TextLabel") then
				textlabel.Text = "Money: "
					.. Alyanum.new(profile.Data.Collector):toString()
					.. "\nRate: "
					.. Alyanum.new(finalRate):toString()
					.. multiplierText
			else
				warn("No textlabel")
			end
			local leaderstats = player:FindFirstChild("leaderstats")
			local Cash = leaderstats.Cash
			Cash.Value = Alyanum.new(profile.Data.Resources.Money):toString()
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

	-- once mount, connect to events
	useEffect(function()
		-- wait for events
		while not Item.Created or not Item.Deleted or not PlayerData.Changed do
			warn("not Item.Created or not Item.Deleted or not PlayerData.Changed", Item)
			task.wait()
		end

		local SellItem: RemoteEvent = game.ReplicatedStorage.Shared.Events:WaitForChild("SellItem")
		local connections = {
			-- when ItemSlots.Changed is fired
			playerSession.StateChanged:Connect(function(pathArray, newValue)
				-- local current = self.Data
				-- -- Navigate to the parent of the target value
				-- for i = 1, #pathArray - 1 do
				-- 	current = current[pathArray[i]]
				-- 	if not current then
				-- 		warn("Invalid path")
				-- 		return
				-- 	end
				-- end
				-- local key = pathArray[#pathArray]
				local pd = PlayerDataService:GetProfile(props.Player).Data
				setPlayerData(table.clone(pd))
			end),
			ISChanged = ItemSlots.Changed:Connect(function(IS: ItemSlots, player)
				if player ~= props.Player then
					return
				end
				setItemSlots(function(prev: ItemSlots)
					local new = table.clone(IS)
					return new
				end)
				if isMountedRef.current then
					game.ReplicatedStorage.Shared.Events.ItemSlotsUpdate:FireClient(props.Player, IS)
				end
			end),

			-- when Item.Created is fired
			ICreated = Item.Created:Connect(function(itms: { Item }, player)
				if player ~= props.Player then
					return
				end

				local newitems = table.clone(PlayerDataService:GetProfile(props.Player).Data.Items)
				setItems(newitems)
			end),

			PDChanged = PlayerData.Changed:Connect(function(pd: PlayerData, player)
				if player ~= props.Player then
					return
				end
				local newitems = table.clone(PlayerDataService:GetProfile(props.Player).Data.Items)
				setItems(newitems)
			end),

			-- when Item.Deleted is fired
			IDeleted = Item.Deleted:Connect(function(itms: { Item }, player)
				if player ~= props.Player then
					return
				end
				local newitems = table.clone(PlayerDataService:GetProfile(props.Player).Data)
				setItems(newitems)
			end),

			sellItemConnection = SellItem.OnServerEvent:Connect(function(player, selectedItemUID: string)
				-- only owner
				if player ~= props.Player then
					return
				end
				if not selectedItemUID then
					return
				end
				local pd = PlayerData.Collections[player]
				-- only item that's valid
				-- only one item amongst all tycoon's slot
				local itemFromUID: Item = pd:GetItemFromUID(selectedItemUID)
				if itemFromUID then
					Item.Sell(itemFromUID, props.Player)
				end
				pd:FireREChanged()
				setItems(table.clone(PlayerDataService:GetProfile(props.Player).Data.Items))
			end),
		}

		return function()
			for i, c in connections do
				c:Disconnect()
			end
			-- props.Plot.Part.BillboardGui.TextLabel.Text = ""
		end
	end, {})

	local placed: { [Slot]: string } = {}
	local placedItems: { [string]: Item } = {}

	local pd = PlayerDataService:GetProfile(props.Player).Data
	-- RENDERING EMPTY SLOTS
	for slotNum: Slot, ItemUID: string in pd.ItemSlots do
		placed[ItemUID] = slotNum
		if ItemUID ~= "none" then
			local item = pd and PlayerData.GetItemFromUID(pd, ItemUID)
			-- check if item is actually exist there. If there is, it will be rendered later.
			-- if itemuid actually leads to no where (deleted, sold) then render empty
			if item then
				continue
			else
				pd.ItemSlots[slotNum] = "none"
				if isMountedRef.current then
					game.ReplicatedStorage.Shared.Events.ItemSlotsUpdate:FireClient(props.Player, pd.ItemSlots)
				end
			end
		end
		children[slotNum] = e(TycoonItem, {
			key = slotNum,
			SlotNum = slotNum,
			Item = nil,
			ItemUID = "none",
			Player = props.Player,
		})
	end
	-- useEffect(function()
	-- 	warn("items set	", items)
	-- end, { items })
	local pd = PlayerDataService:GetProfile(props.Player).Data
	-- RENDERING ITEMS
	local function RunGrowth()
		local s = "running Growth functions:\n"
		for uid, fn in gFRef.current do
			s ..= uid .. ": " .. tostring(fn) .. "\n"
			fn()
		end
	end
	local rate = 0
	for i, item: Item in items or {} do
		local item = pd:GetItemFromUID(item.UID)
		if not item then
			continue
		end
		children[item.UID] = e(OwnedItem, {
			key = item.UID,
			Item = item,
			UID = item.UID,
			RunGrowth = RunGrowth,
		})
		if placed[item.UID] then
			placedItems[item.UID] = item
			local slotNum = placed[item.UID]
			rate += item.Rate
			children[slotNum] = e(TycoonItem, {
				key = slotNum,
				SlotNum = slotNum,
				Item = item,
				ItemUID = item.UID,
				Player = props.Player,
				Rate = item.Rate,
				Plot = props.Plot,
			})

			-- running entry item effect
			local IC = itemConfigs[item.ItemId]
			if not IC then
				continue
			end

			if item.Entered then -- only unEntered need to run
				continue
			end
			if IC.Entry and type(IC.Entry) == "function" then
				task.defer(function()
					IC.Entry(item, props.Player)
					-- item.Entered = true
					-- may cause the Entered guard clause to not
					-- detect since this is a task.defered function
					-- so set outside
				end)
			end
			item.Entered = true
			continue
		end
	end

	local pd = PlayerDataService:GetProfile(props.Player).Data

	local profile = PlayerDataService:GetProfile(props.Player)
	local dummies = require(game.ServerScriptService.Server.Services.Dummies)
	for itemrendererItemId, v in profile.Data.OwnedItems do
		if dummies.ItemConfigs[itemrendererItemId] then
			rate += 1
		end
	end
	rate = (rate < 1 and PlayerDataService:GetProfile(props.Player).Data.Resources.Money < 200) and 1 or rate
	useEffect(function()
		resourcesRef.current.Rate = rate
		profile.Data.Resources.Rate = rate
		local MoneyDisplayUpdate = game.ReplicatedStorage.Shared.Events:FindFirstChild("MoneyDisplayUpdate")
		if not MoneyDisplayUpdate then
			MoneyDisplayUpdate = Instance.new("RemoteEvent")
			MoneyDisplayUpdate.Name = "MoneyDisplayUpdate"
			MoneyDisplayUpdate.Parent = game.ReplicatedStorage.Shared.Events
		end
		if isMountedRef.current then
			MoneyDisplayUpdate:FireClient(props.Player, profile.Data.Resources.Money, resourcesRef.current.Rate or 0)
		end
	end, { rate })
	local piref = useRef()
	--running growth functions
	useEffect(function()
		piref.current = placedItems

		local gF: { [string]: () -> nil? } = {}
		for uid, item in placedItems do
			local IC = itemConfigs[item.ItemId]
			if not IC then
				continue
			end
			if not IC.Growth or type(IC.Growth) ~= "function" then
				continue
			end
			gF[uid] = function()
				IC.Growth(pd:GetItemFromUID(item.UID), props.Player)
			end
		end
		gFRef.current = gF
		setGrowthFunctions(gF)
	end, { items, itemSlots })

	-- MONEY LOOP
	useEffect(function()
		local running = true
		local TweenService = game:GetService("TweenService")
		local Debris = game:GetService("Debris")
		local thread = task.spawn(function()
			while running do
				-- warn("ran")
				task.wait(1)
				local profile = PlayerDataService:GetProfile(props.Player)
				if not profile then
					continue
				end
				if resourcesRef.current.Rate >= 0 then
					-- Apply multipliers to the base rate
					local baseRate = resourcesRef.current.Rate
					local finalMultiplier = MultiplierService.GetFinalMultiplier(props.Player, "Money")
					local finalRate = math.floor(baseRate * finalMultiplier)
					local sum = profile.Data.Collector + finalRate
					local textlabel = props.Plot
						and props.Plot.Collector
						and props.Plot.Collector:FindFirstChild("CollectDisplay") :: Model
						and props.Plot.Collector.CollectDisplay:FindFirstChild("SurfaceGui")
						and props.Plot.Collector.CollectDisplay.SurfaceGui:FindFirstChild("TextLabel")
					if textlabel and textlabel:IsA("TextLabel") then
						-- Display multiplier if active
						local multiplierText = finalMultiplier > 1 and string.format(" (x%.1f)", finalMultiplier) or ""
						textlabel.Text = "Money: "
							.. Alyanum.new(sum):toString()
							.. "\nRate: "
							.. Alyanum.new(finalRate):toString()
							.. multiplierText
					else
						warn("No textlabel")
					end
					profile.Data.Collector = sum

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
	-- warn("props.Items, items", props.Items, items)
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

		local function createTycoon(player: Player)
			warn("player", player)
			if playerSet[player] then
				return
			end
			playerSet[player] = true
			setTycoons(function(prev: { [Player]: TycoonProps })
				warn("setting player", player, "'s tycoon ")

				local newTycoons = table.clone(prev)
				local Plot = PlotService.GetPlot(player)
				local playersItemSlots = PlayerDataService:GetProfile(player).Data.ItemSlots :: ItemSlots?

				if not playersItemSlots then
					warn("Kicking player")
					player:Kick("Sorry failed to fetch player data")
					return newTycoons
				end
				warn("playersItemSlots", playersItemSlots)

				newTycoons[player] = {
					Player = player,
					Plot = Plot,
					ItemSlots = playersItemSlots,
					Items = getItems(player),
					Character = nil,
				}
				warn("newTycoons", newTycoons)
				return newTycoons
			end)
		end

		local function cleanupTycoon(player: Player)
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
			pAddedCon = game.Players.PlayerAdded:Connect(createTycoon),
			pRemovedCon = game.Players.PlayerRemoving:Connect(cleanupTycoon),
		}

		-- iterate Players in case player joined before the connection
		for i, Player: Player in game.Players:GetPlayers() do
			if playerSet[Player] then
				continue
			end
			createTycoon(Player)
		end

		function TycoonService.RestartPlayer(player: Player)
			task.spawn(function()
				cleanupTycoon(player)
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
	local rootFolder = Instance.new("Folder", workspace)
	rootFolder.Name = "TycoonServiceRoot"

	TycoonService.Root = ReactRoblox.createRoot(rootFolder)
	TycoonService.Root:render(e(TycoonApp))
end

return TycoonService

--[[TODO: ======================================================================================================================================================================================================

ITEM EFFECT TYPES: "GROWTH" or "DISCARD" or "ENTRY"

	GROWTH
		taken effect on every pulse (money loop)

	SOLD
		taken effect when is discarded

	ENTRY
		taken effect when is placed for the first time

fn(tycoon) -> effect
======================================================================================================================================================================================================
]]
