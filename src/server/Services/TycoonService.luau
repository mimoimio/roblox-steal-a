local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useRef = React.useRef
local useEffect = React.useEffect
local useState = React.useState

local TycoonService = {}
local ItemSlots = require(game.ServerScriptService.Server.Classes.ItemSlots)
local Item = require(game.ServerScriptService.Server.Classes.Item)

type ItemSlots = { -- contains UID of items from PlayerData.Items
	Slot1: string?,
	Slot2: string?,
	Slot3: string?,
	Slot4: string?,
	Slot5: string?,
	Slot6: string?,
}
type Slot = "Slot1" | "Slot2" | "Slot3" | "Slot4" | "Slot5" | "Slot6"

type Item = {
	UID: string, --
	ItemId: string,
	DisplayName: string,
	Rate: number,
}
type TycoonProps = {
	Player: Player,
	Plot: Part,
	ItemSlots: ItemSlots,
	Items: { Item },
}

local PlayerPlot = {}

function getPlotFromPlayer(Player: Player): Model?
	return PlayerPlot[Player]
end

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
--[[
======================================================================================================================================================================================================
]]

local function TycoonItem(props: { ItemUID: string, Player: Player, SlotNum: Slot })
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

		local PP = Instance.new("ProximityPrompt", slotPart)
		PP.RequiresLineOfSight = false

		local PlaceItem: RemoteEvent = game.ReplicatedStorage.Shared.Events.PlaceItem
		connectionsRef.current = {
			ppconnection = PP.Triggered:Connect(function(playerwhotriggerred)
				PlaceItem:FireClient(playerwhotriggerred, props.SlotNum)
			end),
			placeitemconnection = PlaceItem.OnServerEvent:Connect(function(playerwhofired, slotNum, uid)
				if playerwhofired ~= props.Player then
					return
				end
				if slotNum ~= props.SlotNum then
					return
				else
				end
				if not uid then
					return
				end
				local itemFromUID = pd:GetItemFromUID(uid)
				if not itemFromUID then
					return
				end
				for sn, id in pd.ItemSlots do
					if id == uid then
						pd.ItemSlots[sn] = "none"
					end
					if sn == slotNum then
						pd.ItemSlots[sn] = uid
						warn("Placing", slotNum, uid)
					end
				end

				pd.ItemSlots:FireChangedEvent()
			end),
		}

		--

		if props.ItemUID ~= "none" then
			local item = pd:GetItemFromUID(props.ItemUID)
			assert(item, "NO ITEM WITH UID " .. props.ItemUID .. " FOUND")
			local itemModel = game.ReplicatedStorage.Shared.Models:FindFirstChild(item.ItemId)
			assert(itemModel, "NO ITEM MODEL WITH ID" .. props.ItemUID .. " FOUND")

			local clone: Model = itemModel:Clone()

			clone.Name = "Item" .. props.ItemUID
			clone.PrimaryPart.Anchored = true
			-- .Color = Color3.new(math.random(), math.random(), math.random())
			cloneRef.current = clone
			clone.Parent = workspace
			clone:PivotTo(slotPart:GetPivot() + Vector3.new(0, 5, 0))
		end
		--
		return function()
			for i, cref in connectionsRef.current or {} do
				cref:Disconnect()
			end
			PP:Destroy()
			connectionsRef.current = nil
			if cloneRef.current then
				cloneRef.current:Destroy()
				cloneRef.current = nil
			end
		end
	end, { props.ItemUID, props.SlotNum })

	return e("Model", {
		ref = ref,
		Name = "Item" .. props.ItemUID,
	})
end
--[[
======================================================================================================================================================================================================
]]

local function Tycoon(props: TycoonProps)
	local children = {}
	local money, setMoney = useState(PlayerData.Collections[props.Player].Resources.Money)
	local rateRef = useRef()

	local itemSlots: ItemSlots, setItemSlots = useState(props.ItemSlots)
	local items: { Item }, setItems = useState(props.Items)

	useEffect(function()
		warn("Tycoon for", props.Player.Name, "created")
		while not Item.Created or not Item.Deleted do
			warn("not Item.Created or not Item.Deleted ", Item)
			task.wait()
		end
		local connections = {
			ISChanged = ItemSlots.Changed:Connect(function(IS: ItemSlots, player)
				if player ~= props.Player then
					return
				end
				setItemSlots(IS)
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
		}
		return function()
			for i, c in connections do
				c:Disconnect()
			end
			props.Plot.Part.BillboardGui.TextLabel.Text = ""
		end
	end, {})

	useEffect(function()
		-- warn("itemSlots", itemSlots)
	end, { itemSlots })

	local placed: { [Slot]: string } = {}
	local placedItems: { Item } = {}

	for slotNum: Slot, ItemUID: string in itemSlots do
		-- warn("creating item slotNum", slotNum, ItemUID)
		placed[ItemUID] = true
		children[slotNum] = e(TycoonItem, {
			key = slotNum,
			SlotNum = slotNum,
			ItemUID = ItemUID,
			Player = props.Player,
		})
	end

	for i, item: Item in items or {} do
		if placed[item.UID] then
			table.insert(placedItems, item)
			continue
		end
		children["held" .. item.UID] = e(HeldItem, {
			key = item.UID,
			Player = props.Player,
			Item = item,
		})
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
	end, { rate })

	useEffect(function()
		local running = true
		task.spawn(function()
			while running do
				task.wait(1)
				if rateRef.current > 0 then
					setMoney(function(prev)
						local sum = prev + rateRef.current

						local textlabel: TextLabel = props.Plot.Part.BillboardGui.TextLabel
						textlabel.Text = "Money: " .. sum
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
--[[
======================================================================================================================================================================================================
]]
local Plots = workspace.Plots:GetChildren()

local function getPlot(): Model?
	return table.remove(Plots, #Plots)
end

local function getItems(player: Player): { Item }?
	while not PlayerData.Collections[player] do
		task.wait()
	end
	local items = PlayerData.Collections[player].Items
	return items
end

local function getItemSlots(player: Player): ItemSlots?
	while not PlayerData.Collections[player] do
		task.wait(0.1)
	end
	local itemSlots = PlayerData.Collections[player].ItemSlots
	return itemSlots
end

local function addPlot(Plot: Part): boolean?
	table.insert(Plots, Plot)
	return true
end

-- MANAGES EVERY PLAYER'S TYCOON
local function TycoonApp(props)
	local tycoons: { TycoonProps }, setTycoons = useState({} :: { TycoonProps })

	game.Players.PlayerAdded:Connect(function(player)
		setTycoons(function(prev: { TycoonProps })
			local clone = table.clone(prev)
			local Plot = getPlot()
			PlayerPlot[player] = Plot

			task.spawn(function()
				local char = player.Character or player.CharacterAdded:Wait()
				char:PivotTo(Plot:GetPivot() + Vector3.new(0, 10, 0))
			end)

			table.insert(clone, {
				Player = player,
				Plot = Plot,
				ItemSlots = getItemSlots(player),
				Items = getItems(player),
			})
			return clone
		end)
	end)
	game.Players.PlayerRemoving:Connect(function(player)
		setTycoons(function(prev: { TycoonProps })
			local clone = table.clone(prev)
			for i, tycoon in clone do
				if tycoon.Player == player then
					addPlot(tycoon.Plot)
					table.remove(clone, i)
					return clone
				end
			end
			return clone
		end)
	end)

	local children = {}
	for i, tycoon: TycoonProps in tycoons do
		children[tycoon.Player.Name .. "'s Tycoon"] = e(Tycoon, {
			key = "tycoon" .. tycoon.Player.UserId,
			Player = tycoon.Player,
			Plot = tycoon.Plot,
			ItemSlots = tycoon.ItemSlots,
			Items = tycoon.Items,
		})
	end

	-- useEffect(function()
	-- end, { tycoons })

	return e("Folder", {
		Name = "TycoonApp",
	}, children)
end

function TycoonService.initialize()
	local rootFolder = Instance.new("Folder", workspace)
	rootFolder.Name = "rootFolder"

	TycoonService.Root = ReactRoblox.createRoot(rootFolder)
	TycoonService.Root:render(e(TycoonApp))
end

return TycoonService
