local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "luckyclover",
	DisplayName = "Lucky Clover",
	Rate = 1,
	Price = 30,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Entry = EffectHelpers and function(item, player)
		EffectHelpers.addRateToRandomOwned(item, player, 2)
	end,
	ItemTip = [[<font thickness="2" color="#bbffbb">Entry</font>: Adds 2/s to a random owned generator.]],
} :: ItemConfig
