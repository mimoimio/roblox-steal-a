local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps

return {
	ItemId = "sunpetal",
	DisplayName = "Sun Petal",
	Rate = 15, -- A base rate for the item
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

		local placedItemUids = {}
		for slot, UID in playeritemslots do
			local placedItem = pd:GetItemFromUID(UID)
			if not placedItem then
				continue
			end
			table.insert(placedItemUids, UID)
			placedItem.Rate += 15
		end
		if #placedItemUids <= 0 then
			warn("No placed items")
			return
		end
		-- Fire events to update the client and game state
		playeritemslots:FireChangedEvent()
		Item.FireCreatedEvent(items, player)
		local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
		ItemUpdated:FireClient(player, PlayerData.Collections[player].Items)
	end,
	ItemTip = [[<font thickness="2" color="#bbffbb">Entry</font>: Gives +15/s to every placed item.]],
} :: ItemConfig
