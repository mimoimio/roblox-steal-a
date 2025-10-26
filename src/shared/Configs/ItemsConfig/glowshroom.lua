local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps

return {
	ItemId = "glowshroom",
	DisplayName = "Glowing Mushroom",
	Rate = 15, -- A base rate for the item
	Price = 15000,
	TierId = "uncommon",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Entry = function(item: Item, player: Player)
		local pd = require(game.ServerScriptService.Server.Classes.PlayerData).Collections[player]
		local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
		local Item = require(game.ServerScriptService.Server.Classes.Item)
		local ItemSlots = require(game.ServerScriptService.Server.Classes.ItemSlots)
		local items = pd.Items
		-- Iterate over all owned items (placed or unplaced) and permanently increase their rate

		local playeritemslots
		repeat
			playeritemslots = ItemSlots.Collections[player]
			task.wait()
		until playeritemslots

		local UCItems = {}
		for slot, itm in items do
			local affectedItem = pd:GetItemFromUID(itm.UID)
			if not affectedItem or affectedItem.TierId ~= "uncommon" then
				continue
			end
			table.insert(UCItems, itm.UID)
		end
		if #UCItems <= 0 then
			return
		end
		item.Rate += 13 * #UCItems
		playeritemslots:FireChangedEvent()
		Item.FireCreatedEvent(items, player)
		local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
		ItemUpdated:FireClient(player, PlayerData.Collections[player].Items)
	end,
	ItemTip = [[<font thickness="2" color="#bbffbb">Entry</font>: This generator gets 13/s for every UNCOMMON tier generators currently owned.]],
} :: ItemConfig
