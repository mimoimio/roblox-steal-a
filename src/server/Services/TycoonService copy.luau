-- local sharedtypes = require(game.ReplicatedStorage.Shared.types)
-- type Item = sharedtypes.Item
-- type TycoonProps = sharedtypes.TycoonProps
-- type PlayerData = sharedtypes.PlayerData
-- type ItemConfig = sharedtypes.ItemConfig
-- type ItemSlots = sharedtypes.ItemSlots
-- type Slot = sharedtypes.Slot

-- local ContentProvider = game:GetService("ContentProvider")
-- local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
-- local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
-- local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
-- local React = require(game.ReplicatedStorage.Packages.React)
-- local e = React.createElement
-- local useRef = React.useRef
-- local useEffect = React.useEffect
-- local useState = React.useState
-- local useCallback = React.useCallback

-- local itemConfigs: { ItemConfig } = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
-- local variationConfigs = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
-- local tierConfigs = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)

-- local FormatItemLabelText = require(game.ReplicatedStorage.Shared.Utils.Format).FormatItemLabelText

-- local TycoonService = {}
-- local ItemSlots = require(game.ServerScriptService.Server.Classes.ItemSlots)
-- local Item = require(game.ServerScriptService.Server.Classes.Item)

-- --[[======================================================================================================================================================================================================]]

-- local Plots = workspace.Plots:GetChildren()
-- local PlayerPlot = {}
-- local function getPlot(): Model?
-- 	while #Plots <= 0 do
-- 		warn("waiting for plots", Plots)
-- 		Plots = workspace.Plots:GetChildren()
-- 		task.wait()
-- 	end
-- 	return table.remove(Plots, #Plots)
-- end
-- local function getItems(player: Player): { Item }?
-- 	while not PlayerData.Collections[player] do
-- 		warn("waiting for PlayerData.Collections[player]", player)
-- 		task.wait()
-- 	end
-- 	local items = PlayerData.Collections[player].Items
-- 	return items
-- end
-- local function getItemSlots(player: Player): ItemSlots?
-- 	local start = tick()

-- 	while not PlayerData.Collections[player] do
-- 		-- warn("waiting for PlayerData.Collections[player]", player)
-- 		task.wait(0.1)
-- 		local elapsed = tick() - start
-- 		if elapsed >= 10 then
-- 			break
-- 		end
-- 	end

-- 	if not PlayerData.Collections[player] then -- if failed to fetch playerdata, returns nil
-- 		warn("Player data fetch time out")
-- 		return nil
-- 	end

-- 	local itemSlots = PlayerData.Collections[player].ItemSlots
-- 	return itemSlots
-- end
-- local function addPlot(Plot: Part): boolean?
-- 	table.insert(Plots, Plot)
-- 	return true
-- end
-- function getPlotFromPlayer(Player: Player): Model?
-- 	return PlayerPlot[Player]
-- end

-- --[[======================================================================================================================================================================================================]]

-- local function OwnedItem(props)
-- 	useEffect(function()
-- 		if not props.Item or props.Item.OwnerShipTriggeredGrowth then
-- 			return
-- 		end
-- 		-- warn("This item,", props, "just ran growth")
-- 		props.Item.OwnerShipTriggeredGrowth = true
-- 		props.RunGrowth()
-- 	end, {})
-- 	return e("Folder")
-- end

-- local function TycoonItem(
-- 	props: {
-- 		ItemUID: string | "none",
-- 		Player: Player,
-- 		SlotNum: Slot,
-- 		Item: Item?,
-- 		Rate: number,
-- 		Plot: Model, -- nah
-- 	}
-- )
-- 	local ref = useRef()
-- 	local cloneRef = useRef()
-- 	local slot: Part, setSlot = useState(nil)
-- 	local pd = PlayerData.Collections[props.Player]
-- 	local connectionsRef = useRef()

-- 	-- mount on tycoon's slot model
-- 	useEffect(function()
-- 		local ItemRenderService = require(script.Parent.ItemRenderService)
-- 		local slotsModel = ItemRenderService.GetPlayerItemSlotModels(props.Player, props.SlotNum)
-- 		local slotPart = slotsModel:FindFirstChild("SlotPart") or slotsModel:FindFirstChildWhichIsA("BasePart")
-- 		-- local plot = getPlotFromPlayer(props.Player)
-- 		-- while not plot do
-- 		-- 	plot = getPlotFromPlayer(props.Player)
-- 		-- 	warn("not plot")
-- 		-- 	task.wait()
-- 		-- end
-- 		-- local slotsModel = plot:FindFirstChild("ItemSlots") :: Model?
-- 		-- local slotPart: Part = slotsModel:FindFirstChild(props.SlotNum)
-- 		-- if not slotPart then
-- 		-- 	warn("no slotpart")
-- 		-- 	return
-- 		-- end
-- 		setSlot(slotPart)

-- 		local PlacePP = Instance.new("ProximityPrompt", slotPart)
-- 		PlacePP.HoldDuration = 0
-- 		PlacePP.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
-- 		PlacePP.ActionText = "Place Item"
-- 		PlacePP.MaxActivationDistance = 6
-- 		PlacePP.KeyboardKeyCode = Enum.KeyCode.F
-- 		PlacePP.RequiresLineOfSight = false
-- 		PlacePP.UIOffset = Vector2.new(0, 0)
-- 		local RemovePP
-- 		if props.ItemUID ~= "none" then
-- 			RemovePP = Instance.new("ProximityPrompt", slotPart)
-- 			RemovePP.HoldDuration = 0
-- 			RemovePP.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
-- 			RemovePP.ActionText = "Remove Item"
-- 			RemovePP.MaxActivationDistance = 6
-- 			RemovePP.KeyboardKeyCode = Enum.KeyCode.R
-- 			RemovePP.RequiresLineOfSight = false
-- 			RemovePP.UIOffset = Vector2.new(0, 80)
-- 		end

-- 		local PlaceItem: RemoteEvent = game.ReplicatedStorage.Shared.Events.PlaceItem
-- 		connectionsRef.current = {
-- 			PlacePPConnection = PlacePP.Triggered:Connect(function(playerwhotriggerred)
-- 				if playerwhotriggerred ~= props.Player then
-- 					return
-- 				end
-- 				PlaceItem:FireClient(playerwhotriggerred, props.SlotNum)
-- 			end),
-- 			RemovePPConnection = (function()
-- 				return RemovePP
-- 					and RemovePP.Triggered:Connect(function(playerwhotriggerred)
-- 						if playerwhotriggerred ~= props.Player then
-- 							return
-- 						end
-- 						pd.ItemSlots[props.SlotNum] = "none"
-- 						pd.ItemSlots:FireChangedEvent()
-- 					end)
-- 			end)(),
-- 			--[[
-- 			TycoonApp could be handling ts
-- 			ProximityPromptService.PromptTriggered:Connect( function(prompt:ProximityPrompt, player:Player) end)
-- 			PlaceItem.OnServerEvent:Connect( function( player:Player, slotNum:Slot?, uid?)
-- 				local tycoon:TycoonProps tycoons[Player]
-- 			end)
-- 			]]
-- 			placeitemconnection = PlaceItem.OnServerEvent:Connect(function(playerwhofired, slotNum, uid)
-- 				-- only owner
-- 				if playerwhofired ~= props.Player then
-- 					return
-- 				end
-- 				-- only on slot which was fired from
-- 				if slotNum ~= props.SlotNum then
-- 					return
-- 				else
-- 				end
-- 				-- only request with uid
-- 				if not uid then
-- 					return
-- 				end
-- 				-- only item that's valid
-- 				local itemFromUID = pd:GetItemFromUID(uid)
-- 				if not itemFromUID then
-- 					return
-- 				end
-- 				-- only one item amongst all tycoon's slot
-- 				for sn, id in pd.ItemSlots do
-- 					if id == uid then
-- 						pd.ItemSlots[sn] = "none"
-- 					end
-- 					if sn == slotNum then
-- 						pd.ItemSlots[sn] = uid
-- 					end
-- 				end

-- 				pd.ItemSlots:FireChangedEvent()
-- 			end),
-- 		}

-- 		-- rendering item model
-- 		if props.ItemUID ~= "none" then
-- 			local item = pd:GetItemFromUID(props.ItemUID)
-- 			assert(item, "NO ITEM WITH UID " .. props.ItemUID .. " FOUND")
-- 			local ok, itemModel = pcall(function()
-- 				local model = game.ReplicatedStorage.Shared.Models:FindFirstChild(item.ItemId)
-- 				assert(model, "NO ITEM MODEL WITH ID" .. (props.ItemId or "") .. " FOUND")
-- 				return model
-- 			end)

-- 			if not ok then
-- 				warn(itemModel)
-- 				itemModel = game.ReplicatedStorage.Shared.Models:FindFirstChild("error")
-- 			end

-- 			local clone: Model = itemModel:Clone()

-- 			local tlabel = slotPart
-- 				and slotPart:FindFirstChild("SurfaceGui")
-- 				and slotPart.SurfaceGui:FindFirstChild("TextLabel")
-- 			if tlabel then
-- 				tlabel.Text = FormatItemLabelText(item)
-- 			else
-- 				-- If not found, clone BillboardGui from ReplicatedStorage.Shared
-- 				local billboardGui = game.ReplicatedStorage.Shared:FindFirstChild("BillboardGui")
-- 				if billboardGui then
-- 					local clonedBillboard = billboardGui:Clone()
-- 					clonedBillboard.Parent = clone
-- 					clonedBillboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
-- 					local textLabel = clonedBillboard:FindFirstChild("TextLabel")
-- 					if textLabel and textLabel:IsA("TextLabel") then
-- 						textLabel.Text = FormatItemLabelText(item)
-- 					end
-- 				else
-- 					warn("BillboardGui not found in ReplicatedStorage.Shared")
-- 				end
-- 			end

-- 			clone.PrimaryPart.Anchored = true
-- 			cloneRef.current = clone

-- 			clone.Parent = workspace
-- 			clone:PivotTo(slotPart:GetPivot() + Vector3.new(0, slotPart.Size.Y / 2, 0))
-- 		end

-- 		return function()
-- 			for i, cref in connectionsRef.current or {} do
-- 				cref:Disconnect()
-- 			end
-- 			PlacePP:Destroy()
-- 			if RemovePP then
-- 				RemovePP:Destroy()
-- 			end
-- 			connectionsRef.current = nil
-- 			if cloneRef.current then
-- 				cloneRef.current:Destroy()
-- 				cloneRef.current = nil
-- 			end
-- 		end
-- 	end, { props.ItemUID, props.SlotNum })

-- 	useEffect(function()
-- 		local model = cloneRef.current
-- 		if not model then
-- 			return
-- 		end
-- 		local billboardGui
-- 		-- rendering textlabel
-- 		if props.ItemUID ~= "none" then
-- 			local tlabel = slot and slot:FindFirstChild("SurfaceGui") and slot.SurfaceGui:FindFirstChild("TextLabel")
-- 			if not tlabel then
-- 				warn("NO tlabel")
-- 				-- Instead of setting the SurfaceGui label, create a BillboardGui label above the item model
-- 				billboardGui = game.ReplicatedStorage.Shared.BillboardGui:Clone()
-- 				billboardGui.Parent = model
-- 				billboardGui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)

-- 				local textLabel = billboardGui.TextLabel
-- 				textLabel.Text = FormatItemLabelText(props.Item)

-- 				billboardGui.Parent = slot
-- 				tlabel.Text = FormatItemLabelText(props.Item)
-- 				return
-- 			end
-- 		end
-- 		return function()
-- 			if billboardGui then
-- 				billboardGui:Destroy()
-- 			end
-- 		end
-- 	end, { props.ItemUID, props.SlotNum, props.Rate })

-- 	return e("Model", {
-- 		ref = ref,
-- 		Name = "Item" .. props.ItemUID or "",
-- 	})
-- end

-- --[[======================================================================================================================================================================================================]]

-- local function Tycoon(props: TycoonProps)
-- 	local children = {}
-- 	-- local money, setMoney = useState(PlayerData.Collections[props.Player].Resources.Money)
-- 	local resourcesRef = useRef(PlayerData.Collections[props.Player].Resources)
-- 	local characterRef = useRef()

-- 	local itemSlots: ItemSlots, setItemSlots = useState(props.ItemSlots)
-- 	local items: { Item }, setItems = useState(props.Items)
-- 	local growthFunctions: { [string]: () -> nil? }, setGrowthFunctions = useState({})
-- 	local gFRef = useRef(growthFunctions)

-- 	-- useEffect(function()
-- 	-- 	warn("#items", items)
-- 	-- end, items)

-- 	-- display owner board on tycoon mount
-- 	useEffect(function()
-- 		local plot = props.Plot
-- 		local player = props.Player
-- 		if not plot or not player then
-- 			return
-- 		end

-- 		local ownerBoard = plot:FindFirstChild("OwnerBoard")
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

-- 		return function()
-- 			surfaceGui:Destroy()
-- 		end
-- 	end, { props.Plot, props.Player })

-- 	-- once mount, connect to events
-- 	useEffect(function()
-- 		-- wait for events
-- 		while not Item.Created or not Item.Deleted or not PlayerData.Changed do
-- 			warn("not Item.Created or not Item.Deleted or not PlayerData.Changed", Item)
-- 			task.wait()
-- 		end

-- 		local SellItems: RemoteEvent = game.ReplicatedStorage.Shared.Events:WaitForChild("SellItems")
-- 		local SellItem: RemoteEvent = game.ReplicatedStorage.Shared.Events:WaitForChild("SellItem")
-- 		local connections = {
-- 			-- when ItemSlots.Changed is fired
-- 			ISChanged = ItemSlots.Changed:Connect(function(IS: ItemSlots, player)
-- 				if player ~= props.Player then
-- 					return
-- 				end
-- 				setItemSlots(function(prev: ItemSlots)
-- 					local new = table.clone(IS)
-- 					return new
-- 				end)
-- 				game.ReplicatedStorage.Shared.Events.ItemSlotsUpdate:FireClient(props.Player, IS)
-- 			end),

-- 			-- when Item.Created is fired
-- 			ICreated = Item.Created:Connect(function(itms: { Item }, player)
-- 				if player ~= props.Player then
-- 					return
-- 				end
-- 				local newitems = table.clone(itms)
-- 				setItems(newitems)
-- 			end),

-- 			PDChanged = PlayerData.Changed:Connect(function(pd: PlayerData, player)
-- 				if player ~= props.Player then
-- 					return
-- 				end
-- 				local newitems = table.clone(pd.Items)
-- 				setItems(newitems)
-- 			end),

-- 			-- when Item.Deleted is fired
-- 			IDeleted = Item.Deleted:Connect(function(itms: { Item }, player)
-- 				if player ~= props.Player then
-- 					return
-- 				end
-- 				local newitems = table.clone(itms)
-- 				setItems(newitems)
-- 			end),

-- 			-- handling player sell
-- 			sellItemsConnection = SellItems.OnServerEvent:Connect(
-- 				function(playerwhofired, selectedItemUIDs: { [string]: boolean })
-- 					-- only owner
-- 					if playerwhofired ~= props.Player then
-- 						return
-- 					end
-- 					if not selectedItemUIDs then
-- 						return
-- 					end
-- 					local pd = PlayerData.Collections[playerwhofired]
-- 					-- only item that's valid
-- 					-- only one item amongst all tycoon's slot
-- 					for i, id in selectedItemUIDs do
-- 						local itemFromUID: Item = pd:GetItemFromUID(i)
-- 						if itemFromUID then
-- 							Item.Sell(itemFromUID, props.Player)
-- 						end
-- 					end
-- 					pd:FireREChanged()
-- 					setItems(table.clone(pd.Items))
-- 				end
-- 			),
-- 			sellItemConnection = SellItem.OnServerEvent:Connect(function(playerwhofired, selectedItemUID: string)
-- 				-- only owner
-- 				if playerwhofired ~= props.Player then
-- 					return
-- 				end
-- 				if not selectedItemUID then
-- 					return
-- 				end
-- 				local pd = PlayerData.Collections[playerwhofired]
-- 				-- only item that's valid
-- 				-- only one item amongst all tycoon's slot
-- 				local itemFromUID: Item = pd:GetItemFromUID(selectedItemUID)
-- 				if itemFromUID then
-- 					Item.Sell(itemFromUID, props.Player)
-- 				end
-- 				pd:FireREChanged()
-- 				setItems(table.clone(pd.Items))
-- 			end),
-- 		}

-- 		return function()
-- 			for i, c in connections do
-- 				c:Disconnect()
-- 			end
-- 			-- props.Plot.Part.BillboardGui.TextLabel.Text = ""
-- 		end
-- 	end, {})

-- 	-- displaying stats on player's character everytime character changed
-- 	-- useEffect(function()
-- 	-- 	if not props.Plot then
-- 	-- 		return
-- 	-- 	end

-- 	-- 	local bbGui: BillboardGui = game.ReplicatedStorage.Shared.BillboardGui:Clone()
-- 	-- 	bbGui.Name = "StatsDisplay"
-- 	-- 	bbGui.Parent = props.Plot.PrimaryPart
-- 	-- 	bbGui.Adornee = props.Plot
-- 	-- 	characterRef.current = props.Plot

-- 	-- 	return function()
-- 	-- 		bbGui:Destroy()
-- 	-- 	end
-- 	-- end, { props.Plot })
-- 	-- useEffect(function()
-- 	-- 	if not props.Character then
-- 	-- 		return
-- 	-- 	end

-- 	-- 	local bbGui: BillboardGui = game.ReplicatedStorage.Shared.BillboardGui:Clone()
-- 	-- 	bbGui.Parent = props.Character.PrimaryPart
-- 	-- 	bbGui.Adornee = props.Character.Head
-- 	-- 	-- warn(props.Character.Head)
-- 	-- 	characterRef.current = props.Character

-- 	-- 	return function()
-- 	-- 		bbGui:Destroy()
-- 	-- 	end
-- 	-- end, { props.Character })

-- 	local placed: { [Slot]: string } = {}
-- 	local placedItems: { [string]: Item } = {}

-- 	-- RENDERING EMPTY SLOTS
-- 	for slotNum: Slot, ItemUID: string in itemSlots do
-- 		placed[ItemUID] = slotNum
-- 		if ItemUID ~= "none" then
-- 			local item = PlayerData.Collections[props.Player]
-- 				and PlayerData.Collections[props.Player]:GetItemFromUID(ItemUID)
-- 			-- check if item is actually there. If there is, it will be rendered later.
-- 			-- if itemuid actually leads to no where (deleted, sold) then render empty
-- 			if item then
-- 				continue
-- 			else
-- 				PlayerData.Collections[props.Player].ItemSlots[slotNum] = "none"
-- 				game.ReplicatedStorage.Shared.Events.ItemSlotsUpdate:FireClient(
-- 					props.Player,
-- 					PlayerData.Collections[props.Player].ItemSlots
-- 				)
-- 			end
-- 		end
-- 		children[slotNum] = e(TycoonItem, {
-- 			key = slotNum,
-- 			SlotNum = slotNum,
-- 			Item = nil,
-- 			ItemUID = "none",
-- 			Player = props.Player,
-- 		})
-- 	end
-- 	local pd = PlayerData.Collections[props.Player]
-- 	-- RENDERING ITEMS
-- 	for i, item: Item in items or {} do
-- 		children[item.UID] = e(OwnedItem, {
-- 			key = item.UID,
-- 			Item = pd:GetItemFromUID(item.UID),
-- 			UID = item.UID,
-- 			RunGrowth = function()
-- 				local s = "running Growth functions:\n"
-- 				for uid, fn in gFRef.current do
-- 					-- warn(uid, fn)
-- 					s ..= uid .. ": " .. tostring(fn) .. "\n"
-- 					fn()
-- 				end
-- 				-- warn(s)
-- 			end,
-- 		})
-- 		if placed[item.UID] then
-- 			placedItems[item.UID] = item
-- 			local slotNum = placed[item.UID]
-- 			children[slotNum] = e(TycoonItem, {
-- 				key = slotNum,
-- 				SlotNum = slotNum,
-- 				Item = item,
-- 				ItemUID = item.UID,
-- 				Player = props.Player,
-- 				Rate = item.Rate,
-- 				Plot = props.Plot,
-- 			})
-- 			continue
-- 		else
-- 		end
-- 	end

-- 	-- running entry item effect
-- 	local rate = 0
-- 	local pd = PlayerData.Collections[props.Player]
-- 	for uid, shallowitem in placedItems do
-- 		-- previously entered doesnt work because it's assigned to the shallowly cloned placed items here, not the actual items
-- 		local item = pd:GetItemFromUID(uid)
-- 		if not item then
-- 			continue
-- 		end
-- 		local IC = itemConfigs[item.ItemId]
-- 		if not IC then
-- 			continue
-- 		end

-- 		if item.Entered then
-- 			continue
-- 		end
-- 		if IC.Entry and type(IC.Entry) == "function" then
-- 			item.Entered = true
-- 			task.defer(function()
-- 				IC.Entry(item, props.Player)
-- 				-- item.Entered = true
-- 				-- may cause the Entered guard clause to not
-- 				-- detect since this is a task.defered function
-- 				-- so set outside
-- 			end)
-- 			warn("First time entered")
-- 		end
-- 	end

-- 	for i, item in placedItems do
-- 		rate += item.Rate
-- 	end

-- 	useEffect(function()
-- 		resourcesRef.current.Rate = rate
-- 		PlayerData.Collections[props.Player].Resources.Rate = rate
-- 	end, { rate })

-- 	local piref = useRef()
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
-- 				IC.Growth(pd:GetItemFromUID(item.UID), props.Player)
-- 			end
-- 		end
-- 		gFRef.current = gF
-- 		setGrowthFunctions(gF)
-- 	end, { items, itemSlots })

-- 	-- MONEY LOOP
-- 	useEffect(function()
-- 		local running = true
-- 		task.spawn(function()
-- 			while running do
-- 				-- warn("ran")
-- 				task.wait(1)
-- 				if resourcesRef.current.Rate >= 0 then
-- 					local sum = resourcesRef.current.Money + resourcesRef.current.Rate

-- 					-- Fire unreliable money/rate update for HUD display
-- 					local MoneyDisplayUpdate = game.ReplicatedStorage.Shared.Events:FindFirstChild("MoneyDisplayUpdate")
-- 					if not MoneyDisplayUpdate then
-- 						MoneyDisplayUpdate = Instance.new("RemoteEvent")
-- 						MoneyDisplayUpdate.Name = "MoneyDisplayUpdate"
-- 						MoneyDisplayUpdate.Parent = game.ReplicatedStorage.Shared.Events
-- 					end
-- 					-- Only send money/rate, not full PlayerData
-- 					MoneyDisplayUpdate:FireClient(props.Player, sum, resourcesRef.current.Rate or 0)
-- 					local textlabel = props.Plot
-- 						and props.Plot.Collector
-- 						and props.Plot.Collector:FindFirstChild("CollectDisplay") :: Model
-- 						and props.Plot.Collector.CollectDisplay:FindFirstChild("SurfaceGui")
-- 						and props.Plot.Collector.CollectDisplay.SurfaceGui:FindFirstChild("TextLabel")
-- 					if textlabel and textlabel:IsA("TextLabel") then
-- 						textlabel.Text = "Money: "
-- 							.. Alyanum.new(sum):toString()
-- 							.. "\nRate: "
-- 							.. Alyanum.new(resourcesRef.current.Rate or 0):toString()
-- 					else
-- 						warn("No textlabel")
-- 					end
-- 					resourcesRef.current.Money = sum
-- 				end
-- 			end
-- 		end)
-- 		return function()
-- 			running = false
-- 		end
-- 	end, {}) -- empty deps, runs once
-- 	-- warn("props.Items, items", props.Items, items)
-- 	return e("Folder", { Name = "Player" .. props.Player.Name }, children)
-- end

-- --[[======================================================================================================================================================================================================]]

-- -- MANAGES EVERY PLAYER'S TYCOON
-- local function TycoonApp(props)
-- 	local tycoons: { [Player]: TycoonProps }, setTycoons = useState({} :: { [Player]: TycoonProps })
-- 	local tycoonsRef = useRef({})

-- 	-- Once Mounted
-- 	useEffect(function()
-- 		local playerSet: { [Player]: boolean } = {}

-- 		TycoonService.GetTycoonFromPlayer = Instance.new("BindableFunction")
-- 		TycoonService.GetTycoonFromPlayer.Name = "GetTycoonFromPlayer"
-- 		TycoonService.GetTycoonFromPlayer.OnInvoke = function(player)
-- 			return tycoonsRef.current and tycoonsRef.current[player]
-- 		end

-- 		local function createTycoon(player: Player)
-- 			if playerSet[player] then
-- 				return
-- 			end
-- 			playerSet[player] = true
-- 			setTycoons(function(prev: { [Player]: TycoonProps })
-- 				local newTycoons = table.clone(prev)
-- 				local Plot = getPlot()
-- 				PlayerPlot[player] = Plot
-- 				local cSet = function()
-- 					local char = player.Character or player.CharacterAdded:Wait()
-- 					player.CharacterAdded:Connect(function(cmodel: Model)
-- 						warn("ADDED", cmodel)
-- 						setTycoons(function(prev)
-- 							local clone = table.clone(prev)
-- 							clone[player].Character = cmodel
-- 							return clone
-- 						end)
-- 					end)
-- 					setTycoons(function(prev)
-- 						local clone = table.clone(prev)
-- 						clone[player].Character = char
-- 						return clone
-- 					end)
-- 					char:PivotTo(Plot.PrimaryPart:GetPivot() + Vector3.new(0, 10, 0))
-- 				end
-- 				task.spawn(cSet)

-- 				local playersItemSlots = getItemSlots(player) :: ItemSlots?

-- 				if not playersItemSlots then
-- 					warn("Kicking player")
-- 					player:Kick("Sorry failed to fetch player data")
-- 					return newTycoons
-- 				end

-- 				newTycoons[player] = {
-- 					Player = player,
-- 					Plot = Plot,
-- 					ItemSlots = playersItemSlots,
-- 					Items = getItems(player),
-- 					Character = nil,
-- 				}
-- 				return newTycoons
-- 			end)
-- 		end

-- 		local function cleanupTycoon(player: Player)
-- 			setTycoons(function(prev: { TycoonProps })
-- 				local newTycoons = table.clone(prev)
-- 				if newTycoons[player] then
-- 					addPlot(newTycoons[player].Plot)
-- 					newTycoons[player] = nil
-- 				end
-- 				return newTycoons
-- 			end)
-- 			playerSet[player] = false
-- 		end

-- 		-- on player added and removed
-- 		local pAddedCon = game.Players.PlayerAdded:Connect(createTycoon)
-- 		local pRemovedCon = game.Players.PlayerRemoving:Connect(cleanupTycoon)

-- 		-- iterate Players in case player joined before the connection
-- 		for i, Player: Player in game.Players:GetPlayers() do
-- 			if playerSet[Player] then
-- 				continue
-- 			end
-- 			createTycoon(Player)
-- 		end

-- 		return function()
-- 			if TycoonService.GetTycoonFromPlayer then
-- 				TycoonService.GetTycoonFromPlayer:Destroy()
-- 			end
-- 			if pAddedCon then
-- 				pAddedCon:Disconnect()
-- 			end
-- 			if pRemovedCon then
-- 				pRemovedCon:Disconnect()
-- 			end
-- 		end
-- 	end, {})

-- 	useEffect(function()
-- 		tycoonsRef.current = tycoons
-- 	end, { tycoons })

-- 	local children = {}

-- 	-- warn("tycoons", tycoons)
-- 	for i, tycoon: TycoonProps in tycoons do
-- 		children[tycoon.Player.Name .. "'s Tycoon"] = e(Tycoon, {
-- 			key = "tycoon" .. tycoon.Player.UserId,
-- 			Player = tycoon.Player,
-- 			Plot = tycoon.Plot,
-- 			ItemSlots = tycoon.ItemSlots,
-- 			Items = tycoon.Items,
-- 			Character = tycoon.Character,
-- 		})
-- 	end

-- 	return e("Folder", {
-- 		Name = "TycoonApp",
-- 	}, children)
-- end

-- --[[======================================================================================================================================================================================================]]

-- function TycoonService.initialize()
-- 	if TycoonService.isInitialized then
-- 		return
-- 	end
-- 	TycoonService.isInitialized = true
-- 	local rootFolder = Instance.new("Folder", workspace)
-- 	rootFolder.Name = "rootFolder"

-- 	TycoonService.Root = ReactRoblox.createRoot(rootFolder)
-- 	TycoonService.Root:render(e(TycoonApp))
-- end

-- return TycoonService

-- --[[TODO: ======================================================================================================================================================================================================

-- ITEM EFFECT TYPES: "GROWTH" or "DISCARD" or "ENTRY"

-- 	GROWTH
-- 		taken effect on every pulse (money loop)

-- 	SOLD
-- 		taken effect when is discarded

-- 	ENTRY
-- 		taken effect when is placed for the first time

-- fn(tycoon) -> effect
-- ======================================================================================================================================================================================================
-- ]]
