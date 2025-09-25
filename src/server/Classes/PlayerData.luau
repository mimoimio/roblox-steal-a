type PlayerData = {
	Resources: { [string]: number },
	PlayerSettings: { MusicVolume: number },
	Progress: { EXP: number, LVL: number },
	Items: {
		{
			UID: string,
			ItemId: string,
			DisplayName: string,
			Rate: number,
		}
	},
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
local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)

local ItemSlots = require(game.ServerScriptService.Server.Classes.ItemSlots)
-- local Item = require(game.ServerScriptService.Server.Classes.Item)
--   02:45:30.739  Requested module was required recursively  -  Server - Item:13 do module loader

local PlayerData = {}
PlayerData.__index = PlayerData
PlayerData.Collections = {} -- :: { [Player]: PlayerData }
PlayerData.Owners = {} :: { [PlayerData]: Player }

function PlayerData.new(player: Player)
	local self = setmetatable(PlayerDataService:LoadPlayerData(player), PlayerData)
	self.ItemSlots = ItemSlots.new(self.ItemSlots, player)

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
	warn("NO ITEM", UID, " FOUND IN", pd.Items)
	return
end

function PlayerData:DeleteItem(UID: string)
	local pd: PlayerData = self
	local items: { Item } = pd.Items
	for i, item: Item in items or {} do
		if UID == item.UID then
			table.remove(items, i)
			return true
		end
	end
end

return PlayerData
