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

local useToast = require(script.Parent.Toasts).useToast
local HUD = require(script.Parent.HUD)
local Music = require(script.Parent.Music)
local NpcDialogue = require(script.Parent.NpcDialogue)

type InventoryProps = { PlayerData: PlayerData, InventoryOpen: boolean }
type Panel = "none" | "inventory" | "settings" | "shop" | "mustard" | "music" | "placeitem" | "itemshop"
type Slot = "Slot1" | "Slot2" | "Slot3" | "Slot4" | "Slot5" | "Slot6"

function fetchPlayerData()
	local GetPlayerData: RemoteFunction = game.ReplicatedStorage.Shared.Events:WaitForChild("GetPlayerData")
	local PlayerData = GetPlayerData:InvokeServer()
	return PlayerData
end
local ItemDict: { [string]: Item } = {}

local function Main(props)
	local toast = useToast()
	local items: { Item }, setItems = useState({})
	local activePanel, setActivePanel = React.useState("none" :: Panel)
	local strictPanel, setStrictPanel = useState("none" :: Panel)
	local strictPanelRef = useRef("none")
	local placeSlot: Slot?, setPlaceSlot = useState(nil)

	local SHOWBEAM, setSHOWBEAM = useState(true)

	local submitRef = useRef()
	local PlayerData: PlayerData?, setPlayerData: (PlayerData: PlayerData) -> nil =
		React.useState(fetchPlayerData() :: PlayerData?)
	-- local PlaceItemOpen = activePanel == "placeitem"
	local MusicOpen = activePanel == "music"
	-- local RewardOpen = activePanel == "reward"
	-- local InventoryOpen = activePanel == "inventory"
	-- local ShopOpen = activePanel == "shop"

	-- Toggle helpers
	local function toggle(panel: Panel)
		setActivePanel(function(prev: Panel)
			-- warn("Setting active panel. strictPanel:", strictPanelRef.current)
			if strictPanelRef.current ~= "none" then
				return strictPanelRef.current
			end
			if prev == panel then
				return "none"
			else
				return panel
			end
		end)
	end

	-- local function handleSellItem(itemUID)
	-- 	-- Fire server
	-- 	game.ReplicatedStorage.Shared.Events:WaitForChild("SellItem"):FireServer(itemUID)

	-- 	-- Immediately update local state (optimistic)
	-- 	setPlayerData(function(prevData)
	-- 		local newData = table.clone(prevData)

	-- 		-- Clone Items array and filter out the sold item
	-- 		local newItems = {}
	-- 		for _, item in ipairs(prevData.Items or {}) do
	-- 			if item.UID ~= itemUID then
	-- 				table.insert(newItems, item)
	-- 			end
	-- 		end

	-- 		newData.Items = newItems
	-- 		return newData
	-- 	end)
	-- end

	-- local function toggleStrictPanel(spanel: Panel)
	-- 	setStrictPanel(function(prev)
	-- 		local newpanel
	-- 		if prev == spanel then
	-- 			newpanel = "none"
	-- 		else
	-- 			newpanel = spanel
	-- 		end
	-- 		setActivePanel(newpanel)
	-- 		return newpanel
	-- 	end)
	-- end

	useEffect(function()
		-- warn("strictpanel", strictPanel)
		strictPanelRef.current = strictPanel
	end, { strictPanel })
	useEffect(function()
		-- warn("activePanel", activePanel)
	end, { activePanel })

	--[[ MOUNT HANDLER ]]
	React.useEffect(function()
		local Events = game.ReplicatedStorage.Shared:WaitForChild("Events")
		local GameCompleted = game.ReplicatedStorage.Shared.Events:WaitForChild("GameCompleted")
		local GetItems: RemoteFunction = Events:WaitForChild("GetItems")
		local ItemUpdated: RemoteEvent = Events:WaitForChild("ItemUpdated")
		local ItemSlotsUpdate: RemoteEvent = Events:WaitForChild("ItemSlotsUpdate")
		local PlaceItemEvent: RemoteEvent = Events:WaitForChild("PlaceItem")
		local PlayerDataUpdated: RemoteEvent = Events:WaitForChild("PlayerDataUpdated")
		local Ping: RemoteEvent = Events:WaitForChild("Ping")
		-- Track previous item UIDs for pickup detection
		local previousItemUids = {}

		local connections = {

			--[[ KEYBINDS ================================]]
			keybindconnection = UserInputService.InputBegan:Connect(function(io, gp)
				-- Respect gameProcessed
				if gp then
					return
				end
				if io.KeyCode == Enum.KeyCode.E then
					debug.profilebegin("ACTION_Press_E")
					toggle("inventory")
					debug.profileend()
				-- elseif io.KeyCode == Enum.KeyCode.C then
				-- 	toggle("settings")
				-- elseif io.KeyCode == Enum.KeyCode.R then
				-- 	toggle("reward")
				elseif io.KeyCode == Enum.KeyCode.G then
					toggle("shop")
				end
			end),

			-- ping
			Ping = Ping.OnClientEvent:Connect(function(type)
				task.spawn(function()
					if type == nil then
						local sound: Sound? = game.ReplicatedStorage.Shared.SFX.Ping:FindFirstChildWhichIsA("Sound")
						if sound then
							sound.Parent = game.Players.LocalPlayer
							if not sound.IsLoaded then
								sound.Loaded:Wait()
							end
							sound:Play()
							sound.Ended:Wait()
							sound.Parent = game.ReplicatedStorage.Shared.SFX.Ping
						else
							sound = Instance.new("Sound", game.Players.LocalPlayer)
							if not sound.IsLoaded then
								sound.Loaded:Wait()
							end
							sound:Play()
							sound.Ended:Wait()
							sound:Destroy()
						end
					elseif type == "cash" then
						local sound: Sound? = game.ReplicatedStorage.Shared.SFX:WaitForChild("Cash"):Clone()
						sound.Parent = game.Players.LocalPlayer
						if not sound.IsLoaded then
							sound.Loaded:Wait()
						end
						sound:Play()
						sound.Ended:Wait()
						sound:Destroy()
					elseif type == "gen" then
						task.spawn(function()
							local sound: Sound? = game.ReplicatedStorage.Shared.SFX:WaitForChild("Bass2"):Clone()
							sound.Parent = game.Players.LocalPlayer
							if not sound.IsLoaded then
								sound.Loaded:Wait()
							end
							sound:Play()
							sound.Ended:Wait()
							sound:Destroy()
						end)
						task.spawn(function()
							local sound: Sound? = game.ReplicatedStorage.Shared.SFX:WaitForChild("Bass"):Clone()
							sound.Parent = game.Players.LocalPlayer
							if not sound.IsLoaded then
								sound.Loaded:Wait()
							end
							sound:Play()
							sound.Ended:Wait()
							sound:Destroy()
						end)
						task.spawn(function()
							local sound: Sound? = game.ReplicatedStorage.Shared.SFX.Ping:WaitForChild("Ping"):Clone()
							sound.Parent = game.Players.LocalPlayer
							if not sound.IsLoaded then
								sound.Loaded:Wait()
							end
							sound:Play()
							sound.Ended:Wait()
							sound:Destroy()
						end)
					end
				end)
			end),

			--[[ PLAYER ITEMS UPDATE EVENT ================================]]
			itemupdatedconnection = ItemUpdated.OnClientEvent:Connect(function(fetchedItems: { Item }, Flash: boolean)
				setPlayerData(function(prev: PlayerData)
					local new = table.clone(prev or fetchPlayerData())
					new.Items = fetchedItems

					local newItemDict = {}
					for i, newItem in fetchedItems do
						ItemDict[newItem.UID] = newItem
						newItemDict[newItem.UID] = newItem

						-- Check if this is a new item (not in previous items)
						if not previousItemUids[newItem.UID] then
							-- New item picked up
							toast.open("+ " .. newItem.DisplayName)
							-- local sound: Sound = game.ReplicatedStorage.Shared.SFX:FindFirstChild("PickUp")
							-- if sound then
							-- 	task.spawn(function()
							-- 		sound = sound:Clone()
							-- 		sound.Parent = game.Players.LocalPlayer
							-- 		if not sound.IsLoaded then
							-- 			sound.Loaded:Wait()
							-- 		end
							-- 		sound:Play()
							-- 		sound.Ended:Wait()
							-- 		sound:Destroy()
							-- 	end)
							-- end
						end
					end

					local removedCount = 0

					for uid, item in ItemDict do
						if not newItemDict[uid] then
							ItemDict[uid] = nil
							removedCount += 1
						end
					end

					if removedCount > 0 and Flash then
						toast.open("Removed " .. removedCount .. " items", 3, Color3.new(1, 0, 0))
					end

					-- Update previous items tracking
					previousItemUids = newItemDict

					return new
				end)
				setItems(fetchedItems)
			end),

			PlayerDataUpdated = PlayerDataUpdated.OnClientEvent:Connect(function(pd: PlayerData)
				setPlayerData(function(prev)
					return table.clone(pd)
				end)
			end),

			--[[ PLACE ITEM PROMPT EVENT ================================]]
			placeitemconneciton = PlaceItemEvent.OnClientEvent:Connect(function(SlotNum: Slot)
				if SlotNum ~= placeSlot or not placeSlot then
					toggle("placeitem")
				end
				setPlaceSlot(SlotNum)

				submitRef.current = function(UID: string)
					PlaceItemEvent:FireServer(SlotNum, UID)
					local sound: Sound = game.ReplicatedStorage.Shared.SFX:FindFirstChild("PickUp")
					if sound then
						task.spawn(function()
							sound = sound:Clone()
							sound.Parent = game.Players.LocalPlayer
							if not sound.IsLoaded then
								sound.Loaded:Wait()
							end
							sound:Play()
							sound.Ended:Wait()
							sound:Destroy()
						end)
					end
					-- setActivePanel("none")
					-- setPlaceSlot(nil)
				end
			end),

			--[[ ITEM SLOTS CHANGED EVENT ================================]]
			itemslotschanged = ItemSlotsUpdate.OnClientEvent:Connect(function(ItemSlots: { [string]: string })
				setPlayerData(function(prev: PlayerData)
					if not prev then
						return game.ReplicatedStorage.Shared.Events:WaitForChild("GetPlayerData"):InvokeServer()
					end

					local clone = table.clone(prev)
					clone.ItemSlots = ItemSlots

					return clone
				end)
			end),

			--[[ EXCEEDING ITEM LIMIT ]]
			exceed = Events:WaitForChild("ExceedingLimit").OnClientEvent:Connect(function()
				toast.open("Exceeding Item Limit! Sell current items first!", 5, Color3.new(1, 0.4, 0.4))
				local sound: Sound = game.ReplicatedStorage.Shared.SFX:FindFirstChild("Error")
				if sound then
					task.spawn(function()
						sound = sound:Clone()
						sound.Parent = game.Players.LocalPlayer
						if not sound.IsLoaded then
							sound.Loaded:Wait()
						end
						sound:Play()
						sound.Ended:Wait()
						sound:Destroy()
					end)
				end
			end),

			--[[ GAME COMPLETED ]]
			GameCompleted.OnClientEvent:Connect(function(pd, completedTime, completedMoney)
				setPlayerData(pd)
			end),
		}

		--[[ INITIALIZING ITEMS ================================]]
		local fetchedItems: { Item }? = GetItems:InvokeServer()
		assert(fetchedItems, "FAILED TO GET ITEMS")
		setItems(fetchedItems)
		for i, item in fetchedItems do
			ItemDict[item.UID] = item
			previousItemUids[item.UID] = true
		end

		return function()
			for i, c in connections do
				c:Disconnect()
			end
			submitRef.current = nil
		end
	end, {})

	-- check itemslots if none highlight
	useEffect(function()
		local highlights = {}
		if not PlayerData then
			return
		end

		for slotnum, itemid in PlayerData.ItemSlots do
			if itemid == "none" then
				local model = workspace[game.Players.LocalPlayer.Name .. "ItemRenderer"]
					:WaitForChild("ItemSlots")
					:FindFirstChild(slotnum)
				if not model then
					continue
				end
				local highlight = Instance.new("Highlight", model)
				highlight.FillTransparency = 0.3
				local billboardGui = Instance.new("BillboardGui", model)
				billboardGui.Size = UDim2.new(0, 50, 0, 50)
				billboardGui.AlwaysOnTop = true
				billboardGui.Brightness = 10
				billboardGui.Adornee = model
				billboardGui.Name = "HighlightBillboard"

				local textLabel = Instance.new("TextLabel", billboardGui)
				textLabel.Size = UDim2.new(1, 0, 1, 0)
				textLabel.ZIndex = 100
				textLabel.BackgroundTransparency = 1
				textLabel.Text = "!"
				textLabel.TextStrokeColor3 = Color3.new(1, 0, 0)
				textLabel.TextStrokeTransparency = 0
				textLabel.TextColor3 = Color3.new(1, 1, 1)
				textLabel.TextScaled = true
				textLabel.Font = Enum.Font.GothamBold
				table.insert(highlights, highlight)
				table.insert(highlights, billboardGui)
			end
		end
		return function()
			if not highlights then
				return
			end
			for i, hl in highlights do
				hl:Destroy()
			end
		end
	end, { PlayerData })

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 1,
	}, {
		
		Settings = e(Music, {
			MusicOpen = MusicOpen,
			PlayerData = PlayerData,
			close = function()
				toggle("music")
			end,
		}),
		-- Shop = e(Shop, {
		-- 	ShopOpen = ShopOpen,
		-- 	PlayerData = PlayerData,
		-- 	close = function()
		-- 		toggle("shop")
		-- 	end,
		-- }),
		-- Inventory = InventoryOpen and e(Inventory, {
		-- 	PlayerData = PlayerData,
		-- 	InventoryOpen = InventoryOpen,
		-- 	onSellItem = handleSellItem,
		-- 	close = function()
		-- 		toggle("inventory")
		-- 	end,
		-- 	PlacedItemUids = PlayerData and PlayerData.ItemSlots and (function()
		-- 		local PlacedItemUids = {}
		-- 		for slot, itemuid in PlayerData.ItemSlots do
		-- 			PlacedItemUids[itemuid] = true
		-- 		end
		-- 		return PlacedItemUids
		-- 	end)() or {},
		-- }),
		HUD = e(HUD, {
			activePanel = activePanel,
			PlayerData = PlayerData,
			SHOWBEAM = SHOWBEAM,
			ItemAmt = PlayerData and PlayerData.Items and #PlayerData.Items,
			OnInventoryButtonClick = function()
				toggle("inventory")
			end,
			OnMusicButtonClick = function()
				toggle("music")
			end,
			OnShopButtonClick = function()
				toggle("shop")
			end,
		}),
		Tutorial = not PlayerData.TutorialFinished
				and e(require(script.Parent.Tutorial), {
					PlayerData = PlayerData,
					activePanel = activePanel,
					onFinish = function()
						-- Optimistically mark tutorial finished, then refresh authoritative PlayerData from server
						setPlayerData(function(prev)
							local clone = table.clone(prev or fetchPlayerData())
							clone.TutorialFinished = true
							return clone
						end)
						-- Refresh from server asynchronously
						task.spawn(function()
							local pd = fetchPlayerData()
							if pd then
								setPlayerData(pd)
							end
						end)
					end,
				})
			or nil,
		Completed = PlayerData.GameCompleted and e(require(script.Parent.Completed), {
			PlayerData = PlayerData,
		}),
		NpcDialogue = e(NpcDialogue),
		-- PlaceItem = PlaceItemOpen and e(PlaceItem, {
		-- 	Items = items,
		-- 	PlaceItemOpen = PlaceItemOpen,
		-- 	clicked = function(textbutton: TextButton)
		-- 		local UID = textbutton:GetAttribute("UID") :: string
		-- 		if submitRef and typeof(submitRef.current) == "function" then
		-- 			submitRef.current(UID)
		-- 			-- setActivePanel("none")
		-- 			setItems(function(prev)
		-- 				local clone = table.clone(prev)
		-- 				for i, item in clone do
		-- 					if item.UID == UID then
		-- 						item.Entered = true
		-- 					end
		-- 				end
		-- 				return clone
		-- 			end)
		-- 			local sound: Sound = game.ReplicatedStorage.Shared.SFX:FindFirstChild("PickUp")
		-- 			if sound then
		-- 				task.spawn(function()
		-- 					sound = sound:Clone()
		-- 					sound.Parent = game.Players.LocalPlayer
		-- 					if not sound.IsLoaded then
		-- 						sound.Loaded:Wait()
		-- 					end
		-- 					sound:Play()
		-- 					sound.Ended:Wait()
		-- 					sound:Destroy()
		-- 				end)
		-- 			end
		-- 		else
		-- 			-- warn("No SubmitRef")
		-- 		end
		-- 	end,
		-- 	PlacedItemUids = PlayerData and PlayerData.ItemSlots and (function()
		-- 		local PlacedItemUids = {}
		-- 		for slot, itemuid in PlayerData.ItemSlots do
		-- 			PlacedItemUids[itemuid] = true
		-- 		end
		-- 		return PlacedItemUids
		-- 	end)() or {},
		-- 	PlaceSlot = placeSlot,
		-- 	close = function()
		-- 		setPlaceSlot(nil)
		-- 		setActivePanel("none")
		-- 	end,
		-- }),
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
		}, {}),
	})
end

return Main
