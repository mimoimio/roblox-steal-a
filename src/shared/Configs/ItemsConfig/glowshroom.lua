local isserver = game:GetService("RunService"):IsServer()
local EffectHelpers
if isserver then
	EffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)
end
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig

return {
	ItemId = "glowshroom",
	DisplayName = "Glowing Mushroom",
	Rate = 15,
	Price = 15000,
	TierId = "uncommon",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Entry = EffectHelpers and function(item, player)
		EffectHelpers.customEffect(item, player, function(ctx, currentItem)
			local uncommonCount = 0
			for _, ownedItem in ctx:getOwnedItems() do
				if ownedItem.TierId == "uncommon" then
					uncommonCount += 1
				end
			end
			if uncommonCount > 0 then
				ctx:updateItemRate(currentItem, 13 * uncommonCount)
			end
		end)
	end,
	ItemTip = [[<font thickness="2" color="#bbffbb">Entry</font>: This generator gets 13/s for every UNCOMMON tier generators currently owned.]],
} :: ItemConfig
