--[[
	EffectHelpers: Common item effect patterns
	Provides high-level wrapper functions for typical item effects
]]

local EffectContext = require(script.Parent.EffectContext)

local EffectHelpers = {}

-- Wrapper that handles context creation and cleanup
function EffectHelpers.withContext(item: any, player: Player, callback: (context: any) -> ())
	local ctx = EffectContext.new(item, player)
	if not ctx then
		warn("⚠️ EffectHelpers: Failed to create context")
		return
	end

	callback(ctx)
	ctx:notifyClient()
end

-- Add rate to all placed items
function EffectHelpers.addRateToAllPlaced(item: any, player: Player, amount: number)
	EffectHelpers.withContext(item, player, function(ctx)
		for _, placedItem in ctx:getPlacedItems() do
			ctx:updateItemRate(placedItem, amount)
		end
	end)
end

-- Add rate to random placed item
function EffectHelpers.addRateToRandomPlaced(item: any, player: Player, amount: number)
	EffectHelpers.withContext(item, player, function(ctx)
		local target = ctx:getRandomPlacedItem()
		warn("target", target)
		if target then
			ctx:updateItemRate(target, amount)
		else
			warn("not target")
		end
	end)
end

-- Add rate to all owned items
function EffectHelpers.addRateToAllOwned(item: any, player: Player, amount: number)
	EffectHelpers.withContext(item, player, function(ctx)
		for _, ownedItem in ctx:getOwnedItems() do
			ctx:updateItemRate(ownedItem, amount)
		end
	end)
end

-- Add rate to random owned item
function EffectHelpers.addRateToRandomOwned(item: any, player: Player, amount: number)
	EffectHelpers.withContext(item, player, function(ctx)
		local target = ctx:getRandomOwnedItem()
		if target then
			ctx:updateItemRate(target, amount)
		end
	end)
end

-- Double a random placed item's rate
function EffectHelpers.doubleRandomPlaced(item: any, player: Player)
	EffectHelpers.withContext(item, player, function(ctx)
		local target = ctx:getRandomPlacedItem()
		if target then
			ctx:multiplyItemRate(target, 2)
		end
	end)
end

-- Increase own rate (for Growth effects)
function EffectHelpers.increaseSelfRate(item: any, player: Player, amount: number)
	EffectHelpers.withContext(item, player, function(ctx)
		if not ctx.playerData then
			local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
			ctx.playerData = PlayerData.Collections[player]
		end
		local selfItem = ctx.playerData:GetItemFromUID(item.UID)
		if selfItem then
			ctx:updateItemRate(selfItem, amount)
		end
	end)
end

-- Increase own rate only if placed (for conditional Growth effects)
function EffectHelpers.increaseSelfRateIfPlaced(item: any, player: Player, amount: number)
	EffectHelpers.withContext(item, player, function(ctx)
		local selfItem = ctx.playerData:GetItemFromUID(item.UID)
		if selfItem and ctx:isItemPlaced(selfItem) then
			ctx:updateItemRate(selfItem, amount)
		end
	end)
end

-- Add rate to placed items excluding a specific ItemId
function EffectHelpers.addRateToPlacedExcluding(item: any, player: Player, amount: number, excludeItemId: string)
	EffectHelpers.withContext(item, player, function(ctx)
		for _, placedItem in ctx:getPlacedItems() do
			if placedItem.ItemId ~= excludeItemId then
				ctx:updateItemRate(placedItem, amount)
			end
		end
	end)
end

-- Custom effect with full context access
function EffectHelpers.customEffect(item: any, player: Player, effectFn: (context: any, item: any) -> ())
	EffectHelpers.withContext(item, player, function(ctx)
		effectFn(ctx, item)
	end)
end

return EffectHelpers
