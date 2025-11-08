local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "bamboo",
	DisplayName = "Bamboo",
	Rate = 2,
	Price = 60,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Growth = EffectHelpers and function(item, player)
		EffectHelpers.increaseSelfRateIfPlaced(item, player, 3)
	end,
	ItemTip = [[<font thickness="2" color="#bbffbb">Growth</font>: If placed, increases own rate by 3/s every tick.]],
} :: ItemConfig
