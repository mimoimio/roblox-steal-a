local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "waterleaf",
	DisplayName = "Waterleaf",
	Price = 25,
	Rate = 1,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Growth = isserver and function(item, player)
		local clock = require(game.ServerScriptService.Server.Services.Clock)
		if not clock.IsMorning then
			return
		end
		EffectHelpers.increaseSelfRate(item, player, 1)
	end,
	ItemTip = [[<font thickness ="2" color="#bbffbb">Growth</font>: increases rate by 1/s]],
} :: ItemConfig
