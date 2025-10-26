local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef
local useState = React.useState
local ProximityPromptService = game:GetService("ProximityPromptService")
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
local Inventory = require(script.Parent.Inventory)
local Settings = require(script.Parent.Settings)
local PlaceItem = require(script.Parent.PlaceItem)
local SellItem = require(script.Parent.SellItem)
local HUD = require(script.Parent.HUD)
local Music = require(script.Parent.Music)

type InventoryProps = { PlayerData: PlayerData, InventoryOpen: boolean }
type Panel = "none" | "inventory" | "settings" | "shop" | "mustard" | "music" | "placeitem"
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

	local submitRef = useRef()
	local PlayerData: PlayerData?, setPlayerData: (PlayerData: PlayerData) -> nil =
		React.useState(fetchPlayerData() :: PlayerData?)
	local isMountedRef = useRef()
	local PlaceItemOpen = activePanel == "placeitem"
	local SellItemOpen = activePanel == "sellitem"
	local SettingsOpen = activePanel == "settings"
	local InventoryOpen = activePanel == "inventory"
	local MusicOpen = activePanel == "music"

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

	local function toggleStrictPanel(spanel: Panel)
		setStrictPanel(function(prev)
			local newpanel
			if prev == spanel then
				newpanel = "none"
			else
				newpanel = spanel
			end
			setActivePanel(newpanel)
			return newpanel
		end)
	end

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

		local GetItems: RemoteFunction = Events:WaitForChild("GetItems")
		local ItemUpdated: RemoteEvent = Events:WaitForChild("ItemUpdated")
		local ItemSlotsUpdate: RemoteEvent = Events:WaitForChild("ItemSlotsUpdate")
		local PlaceItemEvent: RemoteEvent = Events:WaitForChild("PlaceItem")
		local SellItemsEvent: RemoteEvent = Events:WaitForChild("SellItems")
		local MainShopEvent: RemoteEvent = Events:WaitForChild("MainShop")
		local Ping: RemoteEvent = Events:WaitForChild("Ping")
		local linvelConn
		local connections = {
			--[[ KEYBINDS ================================]]
			keybindconnection = UserInputService.InputBegan:Connect(function(io, gp)
				-- Respect gameProcessed
				if gp then
					return
				end
				if io.KeyCode == Enum.KeyCode.E then
					toggle("inventory")
				elseif io.KeyCode == Enum.KeyCode.N then
					toggle("music")
				elseif io.KeyCode == Enum.KeyCode.C then
					toggle("settings")
				elseif io.KeyCode == Enum.KeyCode.M then
					toggle("mustard")
				elseif io.KeyCode == Enum.KeyCode.LeftShift then
					warn("Shifted")

					-- local p = game.Players.LocalPlayer
					-- local char = p.Character or p.CharacterAdded:Wait()
					-- local linVel = Instance.new("LinearVelocity", char.PrimaryPart)
					-- local attachment = Instance.new("Attachment", char.PrimaryPart)
					-- linVel.MaxForce = 100000
					-- linVel.Attachment0 = attachment
					-- local start = 1
					-- if linvelConn then
					-- 	linvelConn:Disconnect()
					-- end
					-- local iniVel = char.PrimaryPart.AssemblyLinearVelocity
					-- warn(iniVel.Magnitude)
					-- linvelConn = game:GetService("RunService").Stepped:Connect(function(t, dt)
					-- 	start -= dt
					-- 	linVel.VectorVelocity = ((char.PrimaryPart:GetPivot()).LookVector + Vector3.new(0, 0.5, 0))
					-- 			* 100
					-- 			* (math.max(start, 0))
					-- 		+ char.Humanoid.MoveDirection * char.Humanoid.WalkSpeed
					-- 		+ iniVel
					-- 	iniVel = Vector3.zero
					-- 	-- + Vector3.new(0, start - 1, 0) * workspace.Gravity
					-- end)

					-- task.delay(1 / 60, function()
					-- 	if linvelConn then
					-- 		linvelConn:Disconnect()
					-- 	end
					-- 	if linVel then
					-- 		linVel:Destroy()
					-- 	end
					-- 	if attachment then
					-- 		attachment:Destroy()
					-- 	end
					-- end)
				end
			end),

			-- ping
			Ping = Ping.OnClientEvent:Connect(function()
				task.spawn(function()
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
				end)
			end),

			--[[ PLAYER ITEMS UPDATE EVENT ================================]]
			itemupdatedconnection = ItemUpdated.OnClientEvent:Connect(function(fetchedItems: { Item }, Flash: boolean)
				setPlayerData(function(prev: PlayerData)
					local new = table.clone(prev)
					new.Items = fetchedItems

					local newItemDict = {}
					for i, newItem in fetchedItems do
						ItemDict[newItem.UID] = newItem
						newItemDict[newItem.UID] = newItem
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

					return new
				end)
				setItems(fetchedItems)
			end),

			--[[ PLACE ITEM PROMPT EVENT ================================]]
			placeitemconneciton = PlaceItemEvent.OnClientEvent:Connect(function(SlotNum: Slot)
				toggle("placeitem")
				setPlaceSlot(SlotNum)

				submitRef.current = function(UID: string)
					PlaceItemEvent:FireServer(SlotNum, UID)
					setActivePanel("none")
					setPlaceSlot(nil)
				end
			end),
			--[[ SELL ITEM PROMPT EVENT ================================]]
			sellitemconneciton = SellItemsEvent.OnClientEvent:Connect(function()
				toggleStrictPanel("sellitem")
				-- toggle("sellitem")
			end),
			--[[ MAIN SHOP ]]
			mainshopconneciton = MainShopEvent.OnClientEvent:Connect(function()
				toggleStrictPanel("mainshop")
				-- toggle("mainshop")
			end),

			--[[ ITEM SLOTS CHANGED EVENT ================================]]
			itemslotschanged = ItemSlotsUpdate.OnClientEvent:Connect(function(ItemSlots: { [string]: string })
				setPlayerData(function(prev: PlayerData)
					local clone = table.clone(prev)
					clone.ItemSlots = ItemSlots
					return clone
				end)
			end),

			--[[ STRANGE SPAWNED EVENT ]]
			strange = Events:WaitForChild("StrangeSpawned").OnClientEvent:Connect(function()
				toast.open("Strange Item Spawned!", 8, Color3.new(0.9, 0.4, 0))
				local sound: Sound = game.ReplicatedStorage.Shared.SFX:FindFirstChild("BassEcho")
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
				local sound2 = game.ReplicatedStorage.Shared.SFX:FindFirstChild("Bass")
				if sound2 then
					task.spawn(function()
						sound2 = sound2:Clone()
						sound2.Parent = game.Players.LocalPlayer
						if not sound2.IsLoaded then
							sound2.Loaded:Wait()
						end
						sound2:Play()
						sound2.Ended:Wait()
						sound2:Destroy()
					end)
				end
				local sound3 = game.ReplicatedStorage.Shared.SFX:FindFirstChild("Bass2")
				if sound3 then
					task.spawn(function()
						sound3 = sound3:Clone()
						sound3.Parent = game.Players.LocalPlayer
						if not sound3.IsLoaded then
							sound3.Loaded:Wait()
						end
						sound3:Play()
						sound3.Ended:Wait()
						sound3:Destroy()
					end)
				end
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
		}

		--[[ INITIALIZING ITEMS ================================]]
		local fetchedItems: { Item }? = GetItems:InvokeServer()
		assert(fetchedItems, "FAILED TO GET ITEMS")
		setItems(fetchedItems)
		for i, item in fetchedItems do
			ItemDict[item.UID] = item
		end

		isMountedRef.current = true
		return function()
			for i, c in connections do
				c:Disconnect()
			end
			submitRef.current = nil
		end
	end, {})

	--[[ Rarely used panels]]
	local Panel = PlaceItemOpen
			and e(PlaceItem, {
				Items = items,
				PlaceItemOpen = PlaceItemOpen,
				clicked = function(textbutton: TextButton)
					local UID = textbutton:GetAttribute("UID") :: string
					if submitRef and typeof(submitRef.current) == "function" then
						submitRef.current(UID)
						setActivePanel("none")
					else
						-- warn("No SubmitRef")
					end
				end,
				PlacedItemUids = PlayerData.ItemSlots and (function()
					local PlacedItemUids = {}
					for slot, itemuid in PlayerData.ItemSlots do
						PlacedItemUids[itemuid] = true
					end
					return PlacedItemUids
				end)() or {},
				PlaceSlot = placeSlot,
				close = function()
					setActivePanel("none")
				end,
			})
		or SettingsOpen and e(Settings, {
			SettingsOpen = SettingsOpen,
			PlayerData = PlayerData,
		})
		or SellItemOpen
			and e(SellItem, {
				Items = items,
				SellItemOpen = SellItemOpen,
				close = function()
					toggleStrictPanel("sellitem")
				end,
				sell = function(selectedItems: { string })
					(game.ReplicatedStorage.Shared.Events.SellItems :: RemoteEvent):FireServer(selectedItems)
				end,
				PlacedItemUids = PlayerData.ItemSlots and (function()
					local PlacedItemUids = {}
					for slot, itemuid in PlayerData.ItemSlots do
						PlacedItemUids[itemuid] = true
					end
					return PlacedItemUids
				end)() or {},
			})

	--[[ RENDER ]]
	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 1,
	}, {
		Music = e(Music, {
			MusicOpen = MusicOpen,
			PlayerData = PlayerData,
			close = function()
				toggle("music")
			end,
		}),
		Inventory = e(Inventory, {
			PlayerData = PlayerData,
			InventoryOpen = InventoryOpen,
			isMountedRef = isMountedRef,
			close = function()
				toggle("inventory")
			end,
			PlacedItemUids = PlayerData and PlayerData.ItemSlots and (function()
				local PlacedItemUids = {}
				for slot, itemuid in PlayerData.ItemSlots do
					PlacedItemUids[itemuid] = true
				end
				return PlacedItemUids
			end)() or {},
		}),
		HUD = e(HUD, {
			PlayerData = PlayerData,
			ItemAmt = PlayerData and PlayerData.Items and #PlayerData.Items,
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
		Panel = Panel,
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
		}, {}),
		-- test = e(require(script.Parent.test)),
	})
end

return Main
