local Signal = require(game.ReplicatedStorage.Packages.Signal)
local ProfileStore = require(game.ServerScriptService.Server.Services.ProfileStore)
local sharedtypes = require(game.ReplicatedStorage.Shared.types)

type Item = sharedtypes.Item
type Profile = ProfileStore.Profile<PlayerData>
export type PlayerSession = {
	Player: Player,
	Profile: Profile,
	StateChanged: Signal.Signal,
	AddItem: (self: PlayerSession, item: Item) -> boolean,
	GetItem: (self: PlayerSession, UID: string) -> Item,
	SetItemSlot: (self: PlayerSession, slot: string, UID: string) -> boolean,
	SellItem: (self: PlayerSession, UID: string) -> boolean,
	SellItemBulk: (self: PlayerSession, { string }) -> nil,
}

local PlayerSession: PlayerSession = {}
PlayerSession.__index = PlayerSession

--[[ CONSTRUCTOR ]]
function PlayerSession.new(profile: Profile, player)
	local self: PlayerSession = setmetatable({}, PlayerSession)
	self.Player = player
	self.Profile = profile

	self.ItemPointer = {}
	self:_UpdateItemPointer() -- Internal call

	self.StateChanged = Signal.new()
	profile.OnSessionEnd:Connect(function() end)
	return self :: PlayerSession
end

-------------------------------------------------------------------------------
-- INTERNAL HELPERS (Private)
-- These start with "_" and should NOT be called by other scripts.
-------------------------------------------------------------------------------

-- 1. Pointer Maintenance
function PlayerSession:_UpdateItemPointer()
	table.clear(self.ItemPointer) -- Optimized clear
	for i, item in ipairs(self.Profile.Data.Items) do
		self.ItemPointer[item.UID] = i
	end
end

-- 2. Low Level Data Set (Dangerous if exposed)
function PlayerSession:_Set(pathArray, newValue)
	local current = self.Profile.Data
	for i = 1, #pathArray - 1 do
		current = current[pathArray[i]]
		if not current then
			warn("Invalid path")
			return
		end
	end
	current[pathArray[#pathArray]] = newValue
end

-- 3. Low Level Data Remove (Dangerous if exposed)
function PlayerSession:_Remove(pathArray)
	local current = self.Profile.Data
	for i = 1, #pathArray - 1 do
		current = current[pathArray[i]]
		if not current then
			warn("Invalid path")
			return
		end
	end

	local key = pathArray[#pathArray]
	if type(key) == "number" then
		table.remove(current, key)
	else
		current[key] = nil
	end
end

-------------------------------------------------------------------------------
-- PUBLIC API (Exposed)
-- These are safe to use by your Game Services and UI.
-------------------------------------------------------------------------------

--[[ Inventory Management ]]

function PlayerSession:FireChangedEvent()
	self.StateChanged:Fire()
end

function PlayerSession:AddItem(item: { any })
	-- Public: Other scripts (Quests, Shop) need to give items.
	table.insert(self.Profile.Data.Items, item)
	self:_UpdateItemPointer()
	self.StateChanged:Fire()
end

function PlayerSession:GetItem(UID: string)
	-- Public: UI needs to read item details
	local index = self.ItemPointer[UID]
	return index and self.Profile.Data.Items[index] or nil
end

function PlayerSession:SetItemSlot(targetSlotNum: string, targetUid: string?)
	-- iterate to clear all slots from that item
	for currentSlotNum, currentUid in self.Profile.Data.ItemSlots do
		if currentUid == targetUid then
			self:_Set({ "ItemSlots", currentSlotNum }, "none")
		end
		if currentSlotNum == targetSlotNum then
			self:_Set({ "ItemSlots", targetSlotNum }, targetUid)
		end
	end
	self.StateChanged:Fire()
end

--[[ Economy / Actions ]]

function PlayerSession:SellItem(UID: string)
	local ItemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig) -- Assuming this exists
	local index = self.ItemPointer[UID]
	local item = self.Profile.Data.Items[index]
	if not item then
		return
	end

	-- 1. Run Removal Logic (Callbacks)
	local itemConfig = ItemsConfig[item.ItemId]
	-- if itemConfig and itemConfig.Removed then
	-- itemConfig.Removed(item, self.Player)
	-- end

	-- 2. Unequip if currently equipped
	for slotnum, slotUid in pairs(self.Profile.Data.ItemSlots) do
		if slotUid == UID then
			self:_Set({ "ItemSlots", slotnum }, "none")
		end
	end

	-- 3. Add Money
	-- Note: You had "self.Price" in your code, but price is usually in Config, not the instance
	local price = itemConfig and itemConfig.Price or 0
	self.Profile.Data.Resources.Money += math.floor(price / 2)

	-- 4. Remove Data
	self:_Remove({ "Items", index })
	self:_UpdateItemPointer()

	self.StateChanged:Fire()
end

function PlayerSession:SellItemBulk(UIDs: { string })
	local ItemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig) -- Assuming this exists
	-- Optimization: Don't call SellItem repeatedly, or you rebuild the pointer
	-- and fire StateChanged 50 times for 50 items. Do it in a batch.

	local totalMoney = 0

	-- We need to sort UIDs by index descending so removing them doesn't shift indices of items we haven't processed yet
	-- However, since we use a Pointer map, it's safer to just mark for deletion or use a while loop.
	-- Easiest strategy:

	local itemsSold = false

	for _, UID in ipairs(UIDs) do
		local index = self.ItemPointer[UID]
		local item = self.Profile.Data.Items[index]
		if item then
			itemsSold = true

			-- Logic (Unequip/Callbacks)
			local itemConfig = ItemsConfig[item.ItemId]
			-- if itemConfig and itemConfig.Removed then
			-- 	itemConfig.Removed(item, self.Player)
			-- end

			for slotnum, slotUid in pairs(self.Profile.Data.ItemSlots) do
				if slotUid == UID then
					self:_Set({ "ItemSlots", slotnum }, "none")
				end
			end

			local price = itemConfig and itemConfig.Price or 0
			totalMoney += math.floor(price / 2)

			-- Remove the item from data, but DON'T update pointer yet
			self:_Remove({ "Items", index })

			-- CRITICAL: Because we removed an index, the pointer is now broken for subsequent items in this loop.
			-- We must update the pointer immediately or handle removal differently.
			self:_UpdateItemPointer()
		end
	end

	if itemsSold then
		self.Profile.Data.Resources.Money += totalMoney
		self.StateChanged:Fire()
	end
end

return PlayerSession :: PlayerSession
