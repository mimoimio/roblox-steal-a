local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "bloodthorn",
	DisplayName = "Bloodthorn",
	Rate = 15,
	Price = 15000,
	TierId = "uncommon",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Removed = EffectHelpers and function(item, player)
		EffectHelpers.addRateToPlacedExcluding(item, player, item.Rate, "bloodthorn")
	end,
	ItemTip = [[<font color="#88ff88">When sold:</font>Adds this Item's rate to all placed generators except Bloodthorn ]],
} :: ItemConfig
