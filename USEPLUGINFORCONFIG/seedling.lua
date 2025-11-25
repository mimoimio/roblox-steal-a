local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "seedling",
	DisplayName = "Seedling",
	Rate = 1,
	Price = 35,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Entry = EffectHelpers and function(item, player)
		EffectHelpers.addRateToAllPlaced(item, player, 1)
	end,
	ItemTip = [[<font color="#88ff88">When first placed:</font> Adds 1/s to all owned generators]],
} :: ItemConfig
