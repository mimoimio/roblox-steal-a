local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps
return {
	ItemId = "moonglow",
	DisplayName = "Moonglow",
	Rate = 6,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange", "starlight" },
	Growth = function(item: Item, player: Player)
		local pd = require(game.ServerScriptService.Server.Classes.PlayerData).Collections[player]
		local clock = require(game.ServerScriptService.Server.Services.Clock)
		local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
		if clock.IsMorning then
			warn("NO MORNING")
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

		local max
		for i, selectedItem in items do
			warn("selectedItem", selectedItem.DisplayName)
			selectedItem.Rate = selectedItem.Rate + 3
			max = i
		end
		warn("max", max)

		playeritemslots:FireChangedEvent()
		Item.FireCreatedEvent(items, player)
		local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
		ItemUpdated:FireClient(player, PlayerData.Collections[player].Items)
		--[[
		TODO:
		Fire a Removed effect event, and differentiate with target: Random, select, or all
		]]
	end,
	ItemTip = [[<font thickness ="2" color="#bbffbb">Growth</font>: If it is night, adds 3/s to all item]],
} :: ItemConfig
