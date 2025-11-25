local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "sunpetal",
	DisplayName = "Sun Petal",
	Rate = 15,
	Price = 25000,
	TierId = "rare",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Entry = EffectHelpers and function(item, player)
		local clock = require(game.ServerScriptService.Server.Services.Clock)
		if not clock.IsMorning then
			return
		end
		EffectHelpers.addRateToAllOwned(item, player, 50)
	end,
	ItemTip = [[<font color="#88ff88">When first placed:</font> If it is during <font thickness="2" color="#ffff00">Day</font>, Adds 1/s to all owned generator items]],
} :: ItemConfig
