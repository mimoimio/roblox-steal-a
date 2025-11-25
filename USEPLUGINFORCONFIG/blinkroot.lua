local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "blinkroot",
	DisplayName = "Blinkroot",
	Rate = 1,
	Price = 5000,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Entry = EffectHelpers and function(item, player)
		EffectHelpers.addRateToAllOwned(item, player, 5)
	end,
	ItemTip = [[<font color="#88ff88">When first placed:</font> Adds 5/s to all owned generators]],
} :: ItemConfig
