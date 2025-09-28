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

local TycoonService = {}
local ItemSlots = require(game.ServerScriptService.Server.Classes.ItemSlots)
local Item = require(game.ServerScriptService.Server.Classes.Item)

--[[======================================================================================================================================================================================================]]

local Plots = workspace.Plots:GetChildren()
local PlayerPlot = {}
local function getPlot(): Model?
	return table.remove(Plots, #Plots)
end
local function getItems(player: Player): { Item }?
	while not PlayerData.Collections[player] do
		warn("waiting for PlayerData.Collections[player]", player)
		task.wait()
	end
	local items = PlayerData.Collections[player].Items
	return items
end
local function getItemSlots(player: Player): ItemSlots?
	while not PlayerData.Collections[player] do
		warn("waiting for PlayerData.Collections[player]", player)
		task.wait(0.1)
	end
	local itemSlots = PlayerData.Collections[player].ItemSlots
	return itemSlots
end
local function addPlot(Plot: Part): boolean?
	table.insert(Plots, Plot)
	return true
end
function getPlotFromPlayer(Player: Player): Model?
	return PlayerPlot[Player]
end

--[[======================================================================================================================================================================================================]]

local function TycoonItem(props: { ItemUID: string | "none", Player: Player, SlotNum: Slot, Item: Item? })
	local ref = useRef()
	local cloneRef = useRef()
	local slot: Part, setSlot = useState(nil)
	local pd = PlayerData.Collections[props.Player]
	local connectionsRef = useRef()

	-- mount on tycoon's slot model
	useEffect(function()
		local slotsModel = getPlotFromPlayer(props.Player):FindFirstChild("ItemSlots") :: Model?
		local slotPart: Part = slotsModel:FindFirstChild(props.SlotNum)
		setSlot(slotPart)

		local PlacePP = Instance.new("ProximityPrompt", slotPart)
		PlacePP.HoldDuration = 0
		PlacePP.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
		PlacePP.ActionText = "Place Item"
		PlacePP.MaxActivationDistance = 6
		PlacePP.KeyboardKeyCode = Enum.KeyCode.F
		PlacePP.RequiresLineOfSight = false
		PlacePP.UIOffset = Vector2.new(0, 0)
		local RemovePP
		if props.ItemUID ~= "none" then
			RemovePP = Instance.new("ProximityPrompt", slotPart)
			RemovePP.HoldDuration = 0
			RemovePP.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
			RemovePP.ActionText = "Remove Item"
			RemovePP.MaxActivationDistance = 6
			RemovePP.KeyboardKeyCode = Enum.KeyCode.R
			RemovePP.RequiresLineOfSight = false
			RemovePP.UIOffset = Vector2.new(0, 80)
		end

		local PlaceItem: RemoteEvent = game.ReplicatedStorage.Shared.Events.PlaceItem
		connectionsRef.current = {
			PlacePPConnection = PlacePP.Triggered:Connect(function(playerwhotriggerred)
				if playerwhotriggerred ~= props.Player then
					return
				end
				PlaceItem:FireClient(playerwhotriggerred, props.SlotNum)
			end),
			RemovePPConnection = (function()
				return RemovePP
					and RemovePP.Triggered:Connect(function(playerwhotriggerred)
						if playerwhotriggerred ~= props.Player then
							return
						end
						pd.ItemSlots[props.SlotNum] = "none"
						pd.ItemSlots:FireChangedEvent()
					end)
			end)(),
			--[[
			TycoonApp could be handling ts
			ProximityPromptService.PromptTriggered:Connect( function(prompt:ProximityPrompt, player:Player) end)
			PlaceItem.OnServerEvent:Connect( function( player:Player, slotNum:Slot?, uid?)
				local tycoon:TycoonProps tycoons[Player]
			end)
			]]
			placeitemconnection = PlaceItem.OnServerEvent:Connect(function(playerwhofired, slotNum, uid)
				-- only owner
				if playerwhofired ~= props.Player then
					return
				end
				-- only on slot which was fired from
				if slotNum ~= props.SlotNum then
					return
				else
				end
				-- only request with uid
				if not uid then
					return
				end
				-- only item that's valid
				local itemFromUID = pd:GetItemFromUID(uid)
				if not itemFromUID then
					return
				end
				-- only one item amongst all tycoon's slot
				for sn, id in pd.ItemSlots do
					if id == uid then
						pd.ItemSlots[sn] = "none"
					end
					if sn == slotNum then
						pd.ItemSlots[sn] = uid
					end
				end

				pd.ItemSlots:FireChangedEvent()
			end),
		}

		-- rendering item model
		if props.ItemUID ~= "none" then
			local item = pd:GetItemFromUID(props.ItemUID)
			assert(item, "NO ITEM WITH UID " .. props.ItemUID .. " FOUND")
			local itemModel = game.ReplicatedStorage.Shared.Models:FindFirstChild(item.ItemId)
			assert(itemModel, "NO ITEM MODEL WITH ID" .. props.ItemUID .. " FOUND")

			local clone: Model = itemModel:Clone()

			local tlabel = clone.PrimaryPart.BillboardGui:WaitForChild("TextLabel")
			tlabel.Text = props.Item.DisplayName .. "\n" .. props.Item.Rate .. "/s"
			clone.PrimaryPart.Anchored = true
			cloneRef.current = clone
			clone.Parent = workspace
			clone:PivotTo(slotPart:GetPivot() + Vector3.new(0, slotPart.Size.Y / 2, 0))
		end

		return function()
			for i, cref in connectionsRef.current or {} do
				cref:Disconnect()
			end
			PlacePP:Destroy()
			if RemovePP then
				RemovePP:Destroy()
			end
			connectionsRef.current = nil
			if cloneRef.current then
				cloneRef.current:Destroy()
				cloneRef.current = nil
			end
		end
	end, { props.ItemUID, props.SlotNum })

	useEffect(function()
		local model = cloneRef.current
		if not model then
			return
		end
		-- rendering item model
		if props.ItemUID ~= "none" then
			local tlabel = model.PrimaryPart.BillboardGui:WaitForChild("TextLabel")
			tlabel.Text = props.Item.DisplayName .. "\n" .. props.Item.Rate .. "/s"
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
	local money, setMoney = useState(PlayerData.Collections[props.Player].Resources.Money)
	local rateRef = useRef()
	local characterRef = useRef()

	local itemSlots: ItemSlots, setItemSlots = useState(props.ItemSlots)
	local items: { Item }, setItems = useState(props.Items)

	useEffect(function()
		while not Item.Created or not Item.Deleted do
			warn("not Item.Created or not Item.Deleted ", Item)
			task.wait()
		end

		local SellItems: RemoteEvent = game.ReplicatedStorage.Shared.Events:WaitForChild("SellItems")
		local connections = {
			ISChanged = ItemSlots.Changed:Connect(function(IS: ItemSlots, player)
				if player ~= props.Player then
					return
				end
				setItemSlots(IS)
				game.ReplicatedStorage.Shared.Events.ItemSlotsUpdate:FireClient(props.Player, IS)
			end),
			ICreated = Item.Created:Connect(function(itms: { Item }, player)
				if player ~= props.Player then
					return
				end
				setItems(itms)
			end),
			IDeleted = Item.Deleted:Connect(function(itms: { Item }, player)
				if player ~= props.Player then
					return
				end
				setItems(itms)
			end),
			sellItemConnection = SellItems.OnServerEvent:Connect(
				function(playerwhofired, selectedItemUIDs: { [string]: boolean })
					-- only owner
					if playerwhofired ~= props.Player then
						return
					end
					if not selectedItemUIDs then
						return
					end
					local pd: PlayerData = PlayerData.Collections[playerwhofired]
					-- only item that's valid
					-- only one item amongst all tycoon's slot
					for i, id in selectedItemUIDs do
						local itemFromUID: Item = pd:GetItemFromUID(i)
						if itemFromUID then
							Item.Sell(itemFromUID, props.Player)
							warn("SOLD")
						end
					end
					pd:FireItemUpdateEvent()
					warn(pd)
					setItems(pd.Items)
				end
			),
		}

		return function()
			for i, c in connections do
				c:Disconnect()
			end
			-- props.Plot.Part.BillboardGui.TextLabel.Text = ""
		end
	end, {})

	useEffect(function()
		warn(props.Character, "added")
		if not props.Character then
			return
		end

		local bbGui: BillboardGui = game.ReplicatedStorage.Shared.BillboardGui:Clone()
		bbGui.Parent = props.Character.HumanoidRootPart
		characterRef.current = props.Character

		return function()
			bbGui:Destroy()
		end
	end, { props.Character })

	local placed: { [Slot]: string } = {}
	local placedItems: { [string]: Item } = {}

	-- RENDERING EMPTY SLOTS
	for slotNum: Slot, ItemUID: string in itemSlots do
		placed[ItemUID] = slotNum
		if ItemUID ~= "none" then
			local item = PlayerData.Collections[props.Player]:GetItemFromUID(ItemUID)
			-- check if item is actually there. If there is, it will be rendered later.
			-- if itemuid actually leads to no where (deleted, sold) then render empty
			if item then
				continue
			else
				PlayerData.Collections[props.Player].ItemSlots[slotNum] = "none"
				game.ReplicatedStorage.Shared.Events.ItemSlotsUpdate:FireClient(
					props.Player,
					PlayerData.Collections[props.Player].ItemSlots
				)
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

	-- RENDERING ITEMS
	for i, item: Item in items or {} do
		if placed[item.UID] then
			placedItems[item.UID] = item
			local slotNum = placed[item.UID]
			children[slotNum] = e(TycoonItem, {
				key = slotNum,
				SlotNum = slotNum,
				Item = item,
				ItemUID = item.UID,
				Player = props.Player,
				Rate = item.Rate,
			})
			continue
		end
	end
	local rate = 0
	for i, item in placedItems do
		rate += item.Rate
	end

	useEffect(function()
		PlayerData.Collections[props.Player].Resources.Money = money
	end, { money })

	useEffect(function()
		rateRef.current = rate
		PlayerData.Collections[props.Player].Resources.Rate = rate
	end, { rate })

	local piref = useRef()
	useEffect(function()
		piref.current = placedItems
	end, { placedItems })

	-- MONEY LOOP
	useEffect(function()
		local running = true
		task.spawn(function()
			while running do
				task.wait(1)
				if rateRef.current >= 0 then
					setMoney(function(prev)
						local sum = prev + rateRef.current
						-- for itemUID, item: Item in piref.current or {} do
						-- 	if itemUID == "none" then
						-- 		continue
						-- 	end
						-- 	if item.Effect and item.Effect.growth and typeof(item.Effect.growth) == "function" then
						-- 		item.Effect.growth(PlayerData.Collections[props.Player]:GetItemFromUID(item.UID), props)
						-- 	end
						-- end
						game.ReplicatedStorage.Shared.Events
							:WaitForChild("ResourcesUpdated")
							:FireClient(props.Player, PlayerData.Collections[props.Player].Resources)
						local textlabel = characterRef.current
							and characterRef.current.HumanoidRootPart
							and characterRef.current.HumanoidRootPart:FindFirstChild("BillboardGui")
							and characterRef.current.HumanoidRootPart.BillboardGui:FindFirstChild("TextLabel")
						if textlabel and textlabel:IsA("TextLabel") then
							textlabel.Text = "Money: "
								.. Alyanum.new(sum):toString()
								.. "\nRate: "
								.. Alyanum.new(rateRef.current or 0):toString()
						end

						return sum
					end)
				end
			end
		end)
		return function()
			running = false
		end
	end, {}) -- empty deps, runs once
	-- warn("props.Items, items", props.Items, items)
	return e("Folder", { Name = "Player" .. props.Player.Name }, children)
end

--[[======================================================================================================================================================================================================]]

-- MANAGES EVERY PLAYER'S TYCOON
local function TycoonApp(props)
	local tycoons: { [Player]: TycoonProps }, setTycoons = useState({} :: { [Player]: TycoonProps })

	-- Once Mounted
	useEffect(function()
		local playerSet: { [Player]: boolean } = {}

		local function createTycoon(player: Player)
			if playerSet[player] then
				return
			end
			playerSet[player] = true
			setTycoons(function(prev: { [Player]: TycoonProps })
				local newTycoons = table.clone(prev)
				local Plot = getPlot()
				PlayerPlot[player] = Plot
				local cSet = function()
					local char = player.Character or player.CharacterAdded:Wait()
					player.CharacterAdded:Connect(function(cmodel: Model)
						warn("ADDED", cmodel)
						setTycoons(function(prev)
							local clone = table.clone(prev)
							clone[player].Character = cmodel
							return clone
						end)
					end)
					setTycoons(function(prev)
						local clone = table.clone(prev)
						clone[player].Character = char
						return clone
					end)
					char:PivotTo(Plot.PrimaryPart:GetPivot() + Vector3.new(0, 10, 0))
				end
				task.spawn(cSet)

				newTycoons[player] = {
					Player = player,
					Plot = Plot,
					ItemSlots = getItemSlots(player),
					Items = getItems(player),
					Character = nil,
				}
				return newTycoons
			end)
		end
		local function cleanupTycoon(player: Player)
			setTycoons(function(prev: { TycoonProps })
				local newTycoons = table.clone(prev)
				if newTycoons[player] then
					addPlot(newTycoons[player].Plot)
					newTycoons[player] = nil
				end
				return newTycoons
			end)
			playerSet[player] = false
		end

		local pAddedCon = game.Players.PlayerAdded:Connect(createTycoon)
		local pRemovedCon = game.Players.PlayerRemoving:Connect(cleanupTycoon)

		for i, Player: Player in game.Players:GetPlayers() do
			if playerSet[Player] then
				continue
			end
			createTycoon(Player)
		end

		-- handling place operation
		-- local PlaceItem: RemoteEvent = game.ReplicatedStorage.Shared.Events.PlaceItem
		-- PlaceItem.OnServerEvent:Connect(function(player: Player, slotNum: Slot?, uid: string?)
		-- 	local tycoon: TycoonProps = tycoons[player]
		-- 	local pd: PlayerData = PlayerData.Collections[player]

		-- 	-- only request with slotNum
		-- 	if not slotNum then
		-- 		return
		-- 	end

		-- 	-- only request with uid
		-- 	if not uid then
		-- 		return
		-- 	end

		-- 	-- only item that's valid
		-- 	local itemFromUID = pd:GetItemFromUID(uid)
		-- 	if not itemFromUID then
		-- 		return
		-- 	end

		-- 	-- only one item amongst all tycoon's slot
		-- 	for sn, id in pd.ItemSlots do
		-- 		if id == uid then
		-- 			pd.ItemSlots[sn] = "none"
		-- 		end
		-- 		if sn == slotNum then
		-- 			pd.ItemSlots[sn] = uid
		-- 		end
		-- 	end

		-- end)

		return function()
			if pAddedCon then
				pAddedCon:Disconnect()
			end
			if pRemovedCon then
				pRemovedCon:Disconnect()
			end
		end
	end, {})

	local children = {}

	-- warn("tycoons", tycoons)
	for i, tycoon: TycoonProps in tycoons do
		warn("Player", tycoon.Player, "created tycoon")
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
		Name = "TycoonApp",
	}, children)
end

--[[======================================================================================================================================================================================================]]

function TycoonService.initialize()
	local rootFolder = Instance.new("Folder", workspace)
	rootFolder.Name = "rootFolder"

	TycoonService.Root = ReactRoblox.createRoot(rootFolder)
	TycoonService.Root:render(e(TycoonApp))
end

return TycoonService

--[[TODO: ======================================================================================================================================================================================================

ITEM EFFECT TYPES: "GROWTH" or "DISCARD" or "ENTRY"

	GROWTH
		taken effect on every pulse (money loop)

	DISCARD
		taken effect when is discarded

	ENTRY
		taken effect when is placed for the first time

fn(tycoon) -> effect
======================================================================================================================================================================================================
]]
--[[


local function HeldItem(props: { Player: Player, Item: Item })
	local ref = useRef()
	local cloneRef = useRef()
	local player = props.Player

	-- mount-only (the identifier)
	useEffect(function()
		local node = ref.current
		if not node then
			return
		end

		local item: Item = PlayerData.Collections[player]:GetItemFromUID(props.Item.UID)
		local model: Model = game.ReplicatedStorage.Shared.Models:FindFirstChild(item.ItemId):Clone()
		model.PrimaryPart.Anchored = false

		local clone: Tool = Instance.new("Tool")
		model.Parent = clone
		cloneRef.current = clone

		clone.Name = props.Item.DisplayName
		clone.Enabled = true

		local Handle = Instance.new("Part", clone)
		Handle.Name = "Handle"
		Handle.Size = Vector3.one
		Handle:PivotTo(model:GetPivot())

		local weld = Instance.new("WeldConstraint", Handle)
		weld.Part0 = Handle
		weld.Part1 = model.PrimaryPart

		clone.PrimaryPart = Handle
		task.spawn(function()
			local char = player.Character or player.CharacterAdded:Wait()
			clone.Parent = player.Backpack
		end)
		-- warn(clone, clone.Parent, player.Backpack)

		return function()
			if cloneRef.current then
				cloneRef.current:Destroy()
				cloneRef.current = nil
			end
		end
	end, { props.Item.UID })

	return e("Folder", { Name = props.Item.ItemId, ref = ref })
end

]]
