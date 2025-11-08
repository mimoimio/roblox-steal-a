local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "blinkroot",
	DisplayName = "Blinkroot",
	Rate = 1,
	Price = 25,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Entry = EffectHelpers and function(item, player)
		EffectHelpers.addRateToAllOwned(item, player, 1)
	end,
	ItemTip = [[<font thickness ="2" color="#bbffbb">Entry</font>: Adds 1/s to all owned generators]],
} :: ItemConfig
