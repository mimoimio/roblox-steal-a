local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "daybloom",
	DisplayName = "Daybloom",
	Rate = 1,
	Price = 10,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	-- Entry = isserver and function(item, player)
	-- 	EffectHelpers.addRateToAllOwned(item, player, 3)
	-- end,

	-- ItemTip = [[<font color="#88ff88">When first placed:</font> Gives +3/s to all owned Generator items]],
} :: ItemConfig
