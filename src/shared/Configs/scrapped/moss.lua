local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "moss",
	DisplayName = "Moss",
	Rate = 1,
	Price = 20,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Growth = EffectHelpers and function(item, player)
		EffectHelpers.increaseSelfRate(item, player, 1)
	end,
	ItemTip = [[<font thickness ="2" color="#bbffbb">When you obtain a new item</font>: This item's rate increased by 1/s]],
} :: ItemConfig
