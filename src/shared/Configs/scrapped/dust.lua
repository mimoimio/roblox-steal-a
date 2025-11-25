local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "dust",
	DisplayName = "Dust",
	Rate = 5,
	Price = 100,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	-- Removed = EffectHelpers and function(item, player)
	-- EffectHelpers.doubleRandomPlaced(item, player)
	-- end,
	ItemTip = [[Just a dust.]],
} :: ItemConfig
