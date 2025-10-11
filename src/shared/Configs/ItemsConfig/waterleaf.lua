local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps
return {
	ItemId = "waterleaf",
	DisplayName = "Waterleaf",
	Rate = 7,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Growth = function(item: Item, player: Player)
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

		-- for i, selectedItem in items do
		-- selectedItem.Rate = selectedItem.Rate + 3
		-- end

		pd:GetItemFromUID(item.UID).Rate += 3

		playeritemslots:FireChangedEvent()
		Item.FireCreatedEvent(items, player)
		local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
		ItemUpdated:FireClient(player, PlayerData.Collections[player].Items)
		--[[
		TODO: Fire a Removed effect event, and differentiate with target: Random, select, or all
		]]
	end,
	ItemTip = [[<font thickness ="2" color="#bbffbb">Growth</font>: increases rate by 3/s]],
} :: ItemConfig
