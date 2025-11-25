local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "ash",
	DisplayName = "Ash",
	Rate = 10,
	Price = 250,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	-- Removed = EffectHelpers and function(item, player)
	-- 	EffectHelpers.addRateToRandomPlaced(item, player, 5)
	-- end,
	-- ItemTip = [[<font thickness="2" color="#bbffbb">Sold</font>: Adds 5/s to a random placed generator.]],
	ItemTip = [[Pile of ash.]],
} :: ItemConfig
