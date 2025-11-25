local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "moonglow",
	DisplayName = "Moonglow",
	Price = 40,
	Rate = 1,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange", "starlight" },
	Growth = isserver and function(item, player)
		local clocktime = game.Lighting.ClockTime
		if not (clocktime < 6.5 or clocktime > 0) then
			return
		end
		EffectHelpers.addRateToAllOwned(item, player, 1)
	end,
	ItemTip = [[<font thickness ="2" color="#bbffbb">When you obtain a new item</font>: If it is past midnight before dawn, adds 1/s to all item]],
} :: ItemConfig
