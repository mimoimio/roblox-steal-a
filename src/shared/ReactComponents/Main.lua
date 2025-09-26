local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef
local useState = React.useState
local UserInputService = game:GetService("UserInputService")

type PlayerData = {
	Resources: { [string]: number },
	PlayerSettings: { MusicVolume: number },
	Progress: { EXP: number, LVL: number },
	Items: { { Item } },
	ItemSlots: { -- contains UID of items from PlayerData.Items
		Slot1: string?,
		Slot2: string?,
		Slot3: string?,
		Slot4: string?,
		Slot5: string?,
		Slot6: string?,
	},
}
type Item = {
	UID: string, --
	ItemId: string,
	DisplayName: string,
	Rate: number,
}

local Inventory = require(script.Parent.Inventory)
local PlaceItem = require(script.Parent.PlaceItem)
local HUD = require(script.Parent.HUD)
local Music = require(script.Parent.Music)
local Mustard = require(script.Parent.Mustard)

type InventoryProps = { PlayerData: PlayerData, InventoryOpen: boolean }
type Panel = "none" | "inventory" | "settings" | "shop" | "mustard" | "music" | "placeitem"
type Slot = "Slot1" | "Slot2" | "Slot3" | "Slot4" | "Slot5" | "Slot6"

function fetchPlayerData()
	local GetPlayerData: RemoteFunction = game.ReplicatedStorage.Shared.Events:WaitForChild("GetPlayerData")
	local PlayerData = GetPlayerData:InvokeServer()
	return PlayerData
end

local function Main(props)
	local items: { Item }, setItems = useState({})
	local activePanel, setActivePanel = React.useState("none" :: Panel)
	local placeSlot: Slot?, setPlaceSlot = useState(nil)

	local submitRef = useRef()
	local PlayerData: PlayerData?, setPlayerData: (PlayerData: PlayerData) -> nil =
		React.useState(fetchPlayerData() :: PlayerData?)
	local isMountedRef = useRef()
	local PlaceItemOpen = activePanel == "placeitem"
	local InventoryOpen = activePanel == "inventory"
	local MustardOpen = activePanel == "mustard"
	local MusicOpen = activePanel == "music"

	-- Toggle helpers
	local function toggle(panel: Panel)
		setActivePanel(function(prev: Panel)
			if prev == panel then
				return "none"
			else
				return panel
			end
		end)
	end

	--[[ MOUNT HANDLER ]]
	React.useEffect(function()
		local Events = game.ReplicatedStorage.Shared:WaitForChild("Events")

		local GetItems: RemoteFunction = Events:WaitForChild("GetItems")
		local ItemUpdated: RemoteEvent = Events:WaitForChild("ItemUpdated")

		--[[ KEYBINDS ================================]]
		local keybindconnection = UserInputService.InputBegan:Connect(function(io, gp)
			-- Respect gameProcessed
			if io.KeyCode == Enum.KeyCode.Backquote then
				warn("Backquote", gp)
			end
			if gp then
				return
			end
			if io.KeyCode == Enum.KeyCode.E then
				toggle("inventory")
			elseif io.KeyCode == Enum.KeyCode.N then
				toggle("music")
			elseif io.KeyCode == Enum.KeyCode.M then
				toggle("mustard")
			end
		end)

		--[[ PLAYER ITEMS UPDATE EVENT ================================]]
		local itemupdatedconnection = ItemUpdated.OnClientEvent:Connect(function(fetchedItems: { Item })
			setPlayerData(function(prev: PlayerData)
				local new = table.clone(prev)
				new.Items = fetchedItems
				return new
			end)
			setItems(fetchedItems)
		end)

		--[[ INITIALIZING ITEMS ================================]]
		local fetchedItems: { Item }? = GetItems:InvokeServer()
		assert(fetchedItems, "FAILED TO GET ITEMS")
		setItems(fetchedItems)

		--[[ PLACE ITEM PROMPT EVENT ================================]]
		local PlaceItemEvent: RemoteEvent = Events:WaitForChild("PlaceItem")
		local placeitemconneciton = PlaceItemEvent.OnClientEvent:Connect(function(SlotNum: Slot)
			toggle("placeitem")
			setPlaceSlot(SlotNum)

			submitRef.current = function(UID: string)
				PlaceItemEvent:FireServer(SlotNum, UID)
				setActivePanel("none")
				setPlaceSlot(nil)
			end
		end)

		isMountedRef.current = true
		return function()
			itemupdatedconnection:Disconnect()
			placeitemconneciton:Disconnect()
			keybindconnection:Disconnect()
			submitRef.current = nil
		end
	end, {})

	--[[ RENDER ]]
	-- warn("activePanel", activePanel, "inventoryOpen", InventoryOpen)
	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 0,
	}, {
		Inventory = e(Inventory, {
			PlayerData = PlayerData,
			InventoryOpen = InventoryOpen,
			isMountedRef = isMountedRef,
			close = function()
				toggle("inventory")
			end,
		}),
		PlaceItemPrompt = e(PlaceItem, {
			Items = items,
			PlaceItemOpen = PlaceItemOpen,
			clicked = function(textbutton: TextButton)
				local UID = textbutton:GetAttribute("UID") :: string
				if submitRef and typeof(submitRef.current) == "function" then
					submitRef.current(UID)
					setActivePanel("none")
				else
					warn("No SubmitRef")
				end
			end,
			PlaceSlot = placeSlot,
			close = function()
				setActivePanel("none")
			end,
		}),
		HUD = React.createElement(HUD, {
			PlayerData = PlayerData,
			OnInventoryButtonClick = function()
				toggle("inventory")
			end,
			OnSettingsButtonClick = function()
				toggle("settings")
			end,
			OnMusicButtonClick = function()
				toggle("music")
			end,
		}),
		Music = React.createElement(Music, {
			MusicOpen = MusicOpen,
			close = function()
				toggle("music")
			end,
		}),
		Mustard = React.createElement(Mustard, {
			MustardOpen = MustardOpen,
		}),
		Padding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
		}, {}),
	})
end

return Main
