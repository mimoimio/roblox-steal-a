local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "fireblossom",
	DisplayName = "Fireblossom",
	Rate = 1,
	Price = 25,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Removed = EffectHelpers and function(item, player)
		EffectHelpers.addRateToRandomOwned(item, player, 3)
	end,
	ItemTip = [[<font thickness ="2" color="#bbffbb">Sold</font>: add 3/s to a random owned generator]],
} :: ItemConfig
