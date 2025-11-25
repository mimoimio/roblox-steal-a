local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "spiralaloe",
	DisplayName = "Spiral Aloe",
	Rate = 3333,
	Price = 333333,
	TierId = "rare",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	ItemTip = [[Interesting.]],
} :: ItemConfig
