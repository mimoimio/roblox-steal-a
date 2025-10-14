local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps

return {
	ItemId = "glowshroom",
	DisplayName = "Glowing Mushroom",
	Rate = 16, -- A base rate for the item
	Price = 200,
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
		-- warn("Waiting for playeritemslots")
		until playeritemslots

		local UCplacedItemUids = {}
		for slot, UID in playeritemslots do
			local placedItem = pd:GetItemFromUID(UID)
			if not placedItem or placedItem.TierId ~= "uncommon" then
				continue
			end
			table.insert(UCplacedItemUids, UID)
		end
		if #UCplacedItemUids <= 0 then
			warn("No placed items")
			return
		end
		warn("Placed uncommon items", UCplacedItemUids)
		item.Rate += 13 * #UCplacedItemUids
		-- Fire events to update the client and game state
		playeritemslots:FireChangedEvent()
		Item.FireCreatedEvent(items, player)
		local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
		ItemUpdated:FireClient(player, PlayerData.Collections[player].Items)
	end,
	ItemTip = [[<font thickness="2" color="#bbffbb">Entry</font>: This item gets 13/s for every uncommon item currently placed.]],
} :: ItemConfig
