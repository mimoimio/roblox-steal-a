type Item = {
	UID: string, --
	ItemId: string,
	DisplayName: string,
	Rate: number,
}

local UserInputService = game:GetService("UserInputService")

local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef
local useState = React.useState

-- local function removefirst()
-- 	game.ReplicatedStorage.Shared.Events.RemoveFirst:FireServer()
-- end

-- local function add()
-- 	game.ReplicatedStorage.Shared.Events.AddItem:FireServer()
-- end

-- local function removelast()
-- 	game.ReplicatedStorage.Shared.Events.RemoveItem:FireServer()
-- end
type Slot = "Slot1" | "Slot2" | "Slot3" | "Slot4" | "Slot5" | "Slot6"
local function Main()
	local items: { Item }, setItems = useState({})
	local panel: "none" | "placeitem", setPanel = useState("")
	local placeItemOpen = panel == "placeitem"
	local placeSlot: Slot?, setPlaceSlot = useState(nil)

	local submitRef = useRef()

	local function togglePanel(panel: string)
		setPanel(function(prev)
			return (prev == panel) and "none" or panel
		end)
	end

	React.useEffect(function()
		local Events = game.ReplicatedStorage.Shared:WaitForChild("Events")
		UserInputService.InputBegan:Connect(function(io, gp)
			if gp then
				return
			end
			if io.KeyCode == Enum.KeyCode.E then
				-- 	removefirst()
				-- elseif io.KeyCode == Enum.KeyCode.K then
				-- 	add()
				-- elseif io.KeyCode == Enum.KeyCode.L then
				-- 	removelast()
				-- elseif io.KeyCode == Enum.KeyCode.E then
				-- 	warn("Create Item")
				game.ReplicatedStorage.Shared.Events.CreateItem:FireServer("box")
			end
		end)
		local GetItems: RemoteFunction = Events:WaitForChild("GetItems")
		local ItemUpdated: RemoteEvent = Events:WaitForChild("ItemUpdated")
		local connection = ItemUpdated.OnClientEvent:Connect(function(fetchedItems: { Item })
			setItems(fetchedItems)
		end)
		local fetchedItems: { Item }? = GetItems:InvokeServer()
		assert(fetchedItems, "FAILED TO GET ITEMS")
		setItems(fetchedItems)

		local PlaceItem: RemoteEvent = Events:WaitForChild("PlaceItem")
		local placeitemconneciton = PlaceItem.OnClientEvent:Connect(function(SlotNum: Slot)
			togglePanel("placeitem")
			setPlaceSlot(SlotNum)

			submitRef.current = function(UID: string)
				-- warn("SlotNum", SlotNum)
				-- warn("item.UID", UID)
				PlaceItem:FireServer(SlotNum, UID)
				setPanel("none")
				setPlaceSlot(nil)
			end
		end)

		return function()
			connection:Disconnect()
			placeitemconneciton:Disconnect()
			-- submitRef.current = nil
		end
	end, {})

	local ItemList = {
		UIListLayout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
	}

	for i, item in items do
		ItemList[item.UID] = e("TextButton", {
			AutomaticSize = Enum.AutomaticSize.XY,
			TextSize = 20,
			Text = item.UID .. ", " .. item.DisplayName,
			[React.Event.Activated] = function()
				-- warn("submitRef.current", submitRef.current)
				-- warn("item.UID", item.UID)
				if submitRef.current then
					submitRef.current(item.UID)
				end
			end,
		})
	end

	local children = {
		-- RemoveFirst = e("TextButton", {
		-- 	Position = UDim2.new(0.5, 0, 0.5, -50),
		-- 	AutomaticSize = Enum.AutomaticSize.XY,
		-- 	Text = "Remove Item",
		-- 	[React.Event.Activated] = removefirst,
		-- }),
		-- AddItem = e("TextButton", {
		-- 	Position = UDim2.new(0.5, 0, 0.5, 0),
		-- 	AutomaticSize = Enum.AutomaticSize.XY,
		-- 	Text = "Add Item",
		-- 	[React.Event.Activated] = add,
		-- }),
		-- RemoveItem = e("TextButton", {
		-- 	Position = UDim2.new(0.5, 0, 0.5, 50),
		-- 	AutomaticSize = Enum.AutomaticSize.XY,
		-- 	Text = "Remove Item",
		-- 	[React.Event.Activated] = removelast,
		-- }),
		-- ItemListFrame = ItemListFrame,
	}
	if placeItemOpen and placeSlot then
		children.PlaceItem = e("Frame", {
			AutomaticSize = Enum.AutomaticSize.XY,
		}, {
			UIListLayout = e("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
			TextLabel = e("TextLabel", {
				Text = placeSlot,
			}),
			ItemListFrame = e("Frame", {
				Position = UDim2.new(0, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
			}, ItemList),
		})
	end

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
	}, children)
end

local Root = ReactRoblox.createRoot((function()
	local ScreenGui = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
	ScreenGui.ResetOnSpawn = false
	return ScreenGui
end)())
Root:render(e(Main))
