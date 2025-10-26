local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps

return {
	ItemId = "daybloom",
	DisplayName = "Daybloom",
	Rate = 1,
	Price = 25,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Entry = function(item: Item, player: Player)
		local pd = require(game.ServerScriptService.Server.Classes.PlayerData).Collections[player]
		local clock = require(game.ServerScriptService.Server.Services.Clock)
		local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
		if not clock.IsMorning then
			return
		end
		local Item = require(game.ServerScriptService.Server.Classes.Item)
		local ItemSlots = require(game.ServerScriptService.Server.Classes.ItemSlots)
		local items = pd.Items

		local playeritemslots
		repeat
			playeritemslots = ItemSlots.Collections[player]
			task.wait()
			warn("Waiting for playeritemslots")
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
		warn("#items", #items, "randomItem", randomItem, "playeritemslots", playeritemslots)
		if not randomItem then
			return
		end
		randomItem.Rate = randomItem.Rate + 3

		playeritemslots:FireChangedEvent()
		Item.FireCreatedEvent(items, player)
		local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
		ItemUpdated:FireClient(player, PlayerData.Collections[player].Items)
		--[[
		TODO: Fire a Removed effect event, and differentiate with target: Random, select, or all
		]]
	end,
	ItemTip = [[<font thickness ="2" color="#bbffbb">Entry</font>: If it is morning, adds 3/s to a random placed generator]],
} :: ItemConfig
