local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "embers",
	DisplayName = "Embers",
	Rate = 2,
	Price = 40,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Removed = EffectHelpers and function(item, player)
		EffectHelpers.addRateToAllOwned(item, player, 3)
	end,
	ItemTip = [[<font thickness="2" color="#bbffbb">When sold</font>: Adds 3/s to all owned generators.]],
} :: ItemConfig
