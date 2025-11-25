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
	Rate = 50,
	Price = 50000,
	TierId = "rare",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	Entry = EffectHelpers and function(item, player)
		EffectHelpers.customEffect(item, player, function(ctx, currentItem)
			local uncommonCount = 0
			for _, ownedItem in ctx:getOwnedItems() do
				if ownedItem.TierId == "rare" then
					uncommonCount += 1
				end
			end
			if uncommonCount > 0 then
				ctx:updateItemRate(currentItem, 50 * uncommonCount)
			end
		end)
	end,
	ItemTip = [[<font color="#88ff88">When first placed:</font>This generator gets 50/s for every RARE tier generators currently owned.]],
	-- ItemTip = [[<font thickness="2" color="#bbffbb">Entry</font>: This generator gets 13/s for every UNCOMMON tier generators currently owned.]],
} :: ItemConfig
 