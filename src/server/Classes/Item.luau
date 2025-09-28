local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type Item = sharedtypes.Item
type ItemConfig = sharedtypes.ItemConfig
type PlayerData = sharedtypes.PlayerData

--[[
	Gold, Diamond, Galactic
	Common, Rare, Epic, Legendary, Mythic
]]

local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
local ItemsConfig: { ItemConfig } = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local Item = {}
Item.__index = Item
Item.Collections = {} :: {
	[Player]: { Item },
}
Item.Owners = {} :: {
	[Item]: Player,
}

local c = 0
function count()
	c += 1
	return c
end
local ItemCreated = Instance.new("BindableEvent")
ItemCreated.Name = "ItemCreated"
Item.Created = ItemCreated.Event

local ItemDeleted = Instance.new("BindableEvent")
ItemDeleted.Name = "ItemDeleted"
Item.Deleted = ItemDeleted.Event

local ItemSold = Instance.new("BindableEvent")
ItemSold.Name = "ItemSold"
Item.Sold = ItemSold.Event

function Item.generateUID(Player: Player)
	local UID = ("%014X"):format(tick() * 1e4 + Player.UserId)
	UID = UID:sub(8, UID:len()) .. "_" .. count()
	return UID
end

function Item:FireDeletedEvent()
	local owner: Player = Item.Owners[self]
	ItemDeleted:Fire(Item.Collections[owner], owner)
end
function Item:FireCreatedEvent()
	local owner: Player = Item.Owners[self]
	ItemDeleted:Fire(Item.Collections[owner], owner)
end
function Item:FireSoldEvent(player: Player)
	ItemSold:Fire(PlayerData.Collections[player].Items, player)
end

function Item.new(ItemId: string, Player: Player): Item?
	local itemConfig: ItemConfig? = ItemsConfig[ItemId]
	assert(itemConfig, "NO ITEM WITH ID " .. ItemId .. " FOUND")

	local self = setmetatable(table.clone(itemConfig), Item)
	self.UID = Item.generateUID(Player)

	table.insert(PlayerData.Collections[Player].Items, self)

	ItemCreated:Fire(PlayerData.Collections[Player].Items, Player)

	local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
	ItemUpdated:FireClient(Player, PlayerData.Collections[Player].Items)

	self:FireCreatedEvent()

	return self
end

function Item:Sell(player)
	local pd: PlayerData = PlayerData.Collections[player]
	warn("PlayerData", PlayerData)
	for i, item: Item in pd.Items do
		if item.UID == self.UID then
			table.remove(pd.Items, i)
			pd.Resources.Money += self.Rate
			Item.FireSoldEvent(item, player)
			return
		end
	end
end

return Item
