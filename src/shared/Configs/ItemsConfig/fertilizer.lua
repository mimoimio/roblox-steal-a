local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "fertilizer",
	DisplayName = "Fertilizer",
	Rate = 3,
	Price = 80,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Removed = EffectHelpers and function(item, player)
		EffectHelpers.addRateToAllPlaced(item, player, 10)
	end,
	ItemTip = [[<font thickness="2" color="#bbffbb">Sold</font>: Adds 10/s to all placed generators.]],
} :: ItemConfig
