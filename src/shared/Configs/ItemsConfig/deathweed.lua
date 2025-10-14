local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps
return {
	ItemId = "deathweed",
	DisplayName = "Deathweed",
	Rate = 10,
	Price = 25,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Removed = function(item: Item, player: Player)
		local pd = require(game.ServerScriptService.Server.Classes.PlayerData).Collections[player]
		local Item = require(game.ServerScriptService.Server.Classes.Item)
		local ItemSlots = require(game.ServerScriptService.Server.Classes.ItemSlots)
		local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
		Item.FireCreatedEvent(item, player)
		local items = {  }

		local playeritemslots
		repeat
			playeritemslots = ItemSlots.Collections[player]
			task.wait()
			warn("Waiting for playeritemslots")
		until playeritemslots

		for slot, UID in playeritemslots do
			table.insert(items, UID)
		end

		if #items <= 0 then
			-- warn("Items:", items)
			return
		end
		local randomplacedItem = pd:GetItemFromUID(items[Random.new():NextInteger(1, #items)])
		if not randomplacedItem then
			return
		end
		randomplacedItem.Rate += 10
		playeritemslots:FireChangedEvent()
		Item.FireCreatedEvent(items, player)
		local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
		ItemUpdated:FireClient(player, PlayerData.Collections[player].Items)
	end,
	ItemTip = [[<font thickness ="2">Sold</font>: add 5/s to a random placed item]],
} :: ItemConfig
