local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "deathweed",
	DisplayName = "Deathweed",
	Rate = 1,
	Price = 500,
	TierId = "uncommon",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Removed = EffectHelpers and function(item, player)
		EffectHelpers.addRateToRandomPlaced(item, player, 6)
	end,
	ItemTip = [[ Sell this item to add 6/s to a random placed generator]],
} :: ItemConfig
