local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "morningdew",
	DisplayName = "Morning Dew",
	Rate = 1,
	Price = 50,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Entry = EffectHelpers and function(item, player)
		EffectHelpers.addRateToAllOwned(item, player, 5)
	end,
	ItemTip = [[<font thickness="2" color="#bbffbb">Entry</font>: Adds 5/s to all owned generators.]],
} :: ItemConfig
