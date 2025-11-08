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
	Price = 15000,
	TierId = "uncommon",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Entry = EffectHelpers and function(item, player)
		EffectHelpers.addRateToAllPlaced(item, player, 15)
	end,
	ItemTip = [[<font thickness="2" color="#bbffbb">Entry</font>: Gives +15/s to every placed item.]],
} :: ItemConfig
