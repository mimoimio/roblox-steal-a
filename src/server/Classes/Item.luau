local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type Item = sharedtypes.Item
type ItemConfig = sharedtypes.ItemConfig
type VariationConfig = sharedtypes.VariationConfig
type TierConfig = sharedtypes.TierConfig
type PlayerData = sharedtypes.PlayerData

--[[
	Gold, Diamond, Galactic
	Common, Rare, Epic, Legendary, Mythic
]]

local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)
local ItemsConfig: { ItemConfig } = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local VariationsConfig: { VariationConfig } = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
local TiersConfig: { TierConfig } = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)
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
-- Created:
local ItemDeleted = Instance.new("BindableEvent")
ItemDeleted.Name = "ItemDeleted"
Item.Deleted = ItemDeleted.Event

local ItemSold = Instance.new("BindableEvent")
ItemSold.Name = "ItemSold"
Item.Sold = ItemSold.Event

local ExceedingLimit = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
ExceedingLimit.Name = "ExceedingLimit"

function Item.generateUID(Player: Player)
	local UID = ("%014X"):format(tick() * 1e4 + Player.UserId)
	UID = UID:sub(8, UID:len()) .. "_" .. count()
	return UID
end

function Item:FireDeletedEvent()
	local owner: Player = Item.Owners[self]
	ItemDeleted:Fire(PlayerData.Collections[owner].Items, owner)
end
function Item.FireCreatedEvent(self: Item, owner: Player)
	owner = owner or Item.Owners[self]
	ItemCreated:Fire(PlayerData.Collections[owner].Items, owner)
end
function Item:FireSoldEvent(player: Player)
	ItemSold:Fire(PlayerData.Collections[player].Items, player)
end

function Item.new(ItemId: string, Player: Player, VariationId: string?): Item?
	if #PlayerData.Collections[Player].Items >= 24 then
		ExceedingLimit:FireClient(Player)
		return nil
	end

	local itemConfig: ItemConfig? = ItemsConfig[ItemId]
	local variation: VariationConfig = VariationsConfig[VariationId] or VariationsConfig["none"]
	local tier: TierConfig = TiersConfig[itemConfig.TierId]
	assert(itemConfig, "NO ITEM WITH ID " .. ItemId .. " FOUND")

	local self = setmetatable({}, Item)
	self.UID = Item.generateUID(Player)
	self.ItemId = itemConfig.ItemId
	self.DisplayName = itemConfig.DisplayName
	self.Rate = itemConfig.Rate * variation.Multiplier
	self.VariationId = variation.VariationId
	self.TierId = tier.TierId
	self.Entry = nil
	self.Price = itemConfig.Price
	self.Merge = nil
	self.Removed = nil
	self.Variations = nil
	table.insert(PlayerData.Collections[Player].Items, self)

	ItemCreated:Fire(PlayerData.Collections[Player].Items, Player)

	local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
	ItemUpdated:FireClient(Player, PlayerData.Collections[Player].Items)

	self:FireCreatedEvent(Player)

	return self
end

function Item:Sell(player)
	local pd: PlayerData = PlayerDataService:GetProfile(player).Data
	local TycoonService = require(game.ServerScriptService.Server.Services.TycoonService)
	local playersTycoon = TycoonService.GetTycoonFromPlayer:Invoke(player)
	for i, item: Item in pd.Items do
		if item.UID == self.UID then
			local itemConfig: ItemConfig = ItemsConfig[item.ItemId]
			local removed = itemConfig and type(itemConfig.Removed) == "function" and itemConfig.Removed or nil

			if removed then
				removed(item, player)
			end

			table.remove(pd.Items, i)
			pd.Resources.Money += math.floor(self.Price / 2)
			Item.FireSoldEvent(item, player)

			return
		end
	end
end

return Item
