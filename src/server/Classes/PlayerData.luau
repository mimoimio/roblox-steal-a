local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type Item = sharedtypes.Item
type PlayerData = sharedtypes.PlayerData
type ItemConfig = sharedtypes.ItemConfig

local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)

local ItemSlots = require(game.ServerScriptService.Server.Classes.ItemSlots)
local PlayerSettings = require(game.ServerScriptService.Server.Classes.PlayerSettings)
local ItemsConfig: { ItemConfig } = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
-- local Item = require(game.ServerScriptService.Server.Classes.Item)
--   02:45:30.739  Requested module was required recursively  -  Server - Item:13 do module loader

local PlayerData = {} :: {
	Collections: { [Player]: PlayerData },
	Owners: { [PlayerData]: Player },
}
PlayerData.__index = PlayerData
PlayerData.Collections = {} :: { [Player]: PlayerData }
PlayerData.Owners = {} :: { [PlayerData]: Player }
local Changed = Instance.new("BindableEvent")
PlayerData.Changed = Changed.Event

function PlayerData.new(player: Player)
	local self = setmetatable(PlayerDataService:LoadPlayerData(player), PlayerData)
	self.ItemSlots = ItemSlots.new(self.ItemSlots, player)
	self.PlayerSettings = PlayerSettings.new(player, self.PlayerSettings)

	for i, c: Item in self.Items do
		local itemConfig: ItemConfig? = ItemsConfig[c.ItemId]
		c.Effect = itemConfig.Effect
	end

	warn(self)

	PlayerData.Owners[self] = player
	PlayerData.Collections[player] = self

	return self
end

function PlayerData:GetItemFromUID(UID: string): Item?
	local pd: PlayerData = self
	local items: { Item } = pd.Items
	for i, item: Item in items or {} do
		if UID == item.UID then
			return item
		end
	end
	-- warn("NO ITEM", UID, " FOUND IN", pd.Items)
	return
end

function PlayerData:FireItemUpdateEvent()
	local self: PlayerData = self
	local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
	ItemUpdated:FireClient(PlayerData.Owners[self], self.Items)
end

function PlayerData:DeleteItem(UID: string)
	local pd: PlayerData = self
	local items: { Item } = pd.Items
	for i, item: Item in items or {} do
		if UID == item.UID then
			table.remove(items, i)
			pd:FireItemUpdateEvent()
			return true
		end
	end
end

return PlayerData :: PlayerData
