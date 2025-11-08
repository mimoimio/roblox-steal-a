local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "daybloom",
	DisplayName = "Daybloom",
	Rate = 1,
	Price = 25,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Entry = isserver and function(item, player)
		local clock = require(game.ServerScriptService.Server.Services.Clock)
		if not clock.IsMorning then
			return
		end
		EffectHelpers.addRateToRandomPlaced(item, player, 3)
	end,
	ItemTip = [[<font thickness ="2" color="#bbffbb">Entry</font>: If it is morning, adds 3/s to a random placed generator]],
} :: ItemConfig
