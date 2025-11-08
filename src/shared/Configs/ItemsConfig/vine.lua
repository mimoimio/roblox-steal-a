local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "vine",
	DisplayName = "Vine",
	Rate = 1,
	Price = 45,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Growth = EffectHelpers and function(item, player)
		EffectHelpers.increaseSelfRate(item, player, 2)
	end,
	ItemTip = [[<font thickness="2" color="#bbffbb">Growth</font>: Increases own rate by 2/s every tick.]],
} :: ItemConfig
