local Signal = require(game.ReplicatedStorage.Packages.Signal)
local ProfileStore = require(game.ServerScriptService.Server.Services.ProfileStore)
local sharedtypes = require(game.ReplicatedStorage.Shared.types)

type PlayerData = sharedtypes.PlayerData
type Profile = ProfileStore.Profile<PlayerData>
type Signal = Signal.Signal
export type PlayerSession = {
	Player: Player,
	Profile: Profile,
	Data: PlayerData,
	StateChanged: Signal,
	MoneyChanged: Signal,
	InventoryChanged: Signal,
}

local PlayerSession = {}
PlayerSession.__index = PlayerSession

function PlayerSession.new(profile: Profile, player: Player)
	local self = setmetatable({}, PlayerSession)
	self.Player = player
	self.Profile = profile
	self.OriginalData = profile.Data
	self.Data = table.clone(profile.Data) -- this contains itempointer
	self.Items = self.Data.Items
	self.ItemSlots = self.Data.ItemSlots

	self.Data.ItemPointer = {}
	self:UpdateItemPointer()

	self.StateChanged = Signal.new()

	return self
end

function PlayerSession:UpdateItemPointer()
	self.Data.ItemPointer = {}
	for i, item in ipairs(self.Items) do
		self.Data.ItemPointer[item.UID] = i
	end
end

function PlayerSession:Set(pathArray, newValue)
	local current = self.Data
	-- Navigate to the parent of the target value
	for i = 1, #pathArray - 1 do
		current = current[pathArray[i]]
		if not current then
			warn("Invalid path")
			return
		end
	end
	local key = pathArray[#pathArray]
	current[key] = newValue
end

function PlayerSession:Remove(pathArray)
	local current = self.Data
	-- Navigate to the parent of the target value
	for i = 1, #pathArray - 1 do
		current = current[pathArray[i]]
		if not current then
			warn("Invalid path")
			return
		end
	end
	local parent = current
	local index = pathArray[#pathArray]
	if type(index) == "number" then
		table.remove(parent, index)
	else
		parent[index] = nil
	end
end

-- Itemslots manipulation
--[[ external use ]]
function PlayerSession:SetItemSlotEmpty(slotnum)
	local pathArray = { "ItemSlots", slotnum }
	self:Set(pathArray, "none")
	self.StateChanged:Fire()
end
--[[ external use ]]
function PlayerSession:SetItemSlot(slotnum, uid)
	local pathArray = { "ItemSlots", slotnum }
	self:Set(pathArray, uid)
	self.StateChanged:Fire()
end

--[[ Item manipulations ]]

--[[ for internal uses only. No event firing ]]
function PlayerSession:AddItem(item: { any })
	table.insert(self.Items, item)
	self:UpdateItemPointer()
end
function PlayerSession:RemoveItem(UID: string)
	local index = self.Data.ItemPointer[UID]
	for slotnum, uid in self.ItemSlots do
		if self.Items[index].UID == uid then
			self.ItemSlots[slotnum] = "none"
		end
	end
	self:Remove({ "Items", index })
	self:UpdateItemPointer()
end
function PlayerSession:SetItemAttribute(UID: string, attr: string, value: any)
	local index = self.Data.ItemPointer[UID]
	self.Items[index][attr] = value
end
--[[ external uses. Fires events]]
function PlayerSession:SellItem(UID: string)
	local index = self.Data.ItemPointer[UID]
	local item = self.Data.Items[index]

	local itemConfig: ItemConfig = ItemsConfig[item.ItemId]
	local removed = itemConfig and type(itemConfig.Removed) == "function" and itemConfig.Removed or nil

	if removed then
		removed(item, self.Player)
	end

	self:RemoveItem(item.UID)
	self.Data.Resources.Money += math.floor(self.Price / 2)
	self.StateChanged:Fire()
	-- FireSoldEvent(item, player)
end
function PlayerSession:SellItemBulk(UIDs: { string })
	for i, UID in UIDs do
		local index = self.Data.ItemPointer[UID]
		local item = self.Data.Items[index]

		local itemConfig = ItemsConfig[item.ItemId]
		local removed = itemConfig and type(itemConfig.Removed) == "function" and itemConfig.Removed or nil

		if removed then
			removed(item, self.Player)
		end

		self:RemoveItem(item.UID)
		self.Data.Resources.Money += math.floor(self.Price / 2)
	end
	self.StateChanged:Fire()
	-- Item.FireSoldBulkEvent(item, player)
end

return PlayerSession
