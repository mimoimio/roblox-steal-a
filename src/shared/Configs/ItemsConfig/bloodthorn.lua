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
	ItemTip = [[<font thickness="2" color="#bbffbb">Sold</font>: Placed generators that are not bloodthorn get this generator's rate]],
} :: ItemConfig
