local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps
return {
	ItemId = "fireblossom",
	DisplayName = "Fireblossom",
	Rate = 1,
	Price = 25,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Removed = function(item: Item, player: Player)
		local ItemSlots = require(game.ServerScriptService.Server.Classes.ItemSlots)
		local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
		local Item = require(game.ServerScriptService.Server.Classes.Item)
		local pd = require(game.ServerScriptService.Server.Classes.PlayerData).Collections[player]

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
		end
		if #placedItemUids <= 0 then
			warn("No placed items")
			return
		end
		local randomItem = pd:GetItemFromUID(placedItemUids[Random.new():NextInteger(1, #placedItemUids)])
		if not randomItem then
			warn("No random item")
			return
		end
		randomItem.Rate += 3
		playeritemslots:FireChangedEvent()
		Item.FireCreatedEvent(pd.Items, player)
		local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
		ItemUpdated:FireClient(player, PlayerData.Collections[player].Items)
	end,
	ItemTip = [[<font thickness ="2" color="#bbffbb">Sold</font>: add 3/s to a random owned generator]],
} :: ItemConfig

--[[

Removed:
	- remove item from list
	- do effect
	Item removed wont be taken into account.
	So Removed effect will run all at once AFTER 
	ONE REMOVE (May include many items like 
	selling many items at once) OPERATION.

Entry:
	- add item to the list.
	- do effect
	- added item will be taken into account

Growth:
	- if includes other items, added should
	be taken into account

]]
