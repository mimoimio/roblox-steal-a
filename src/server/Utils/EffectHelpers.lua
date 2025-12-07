--[[
	EffectHelpers: Common item effect patterns
	Provides high-level wrapper functions for typical item effects
]]


local EffectContext = require(script.Parent.EffectContext)
local EffectHelpers = {}

--[[ 
    WRAPPER: Handles the Batching
    1. Creates Context
    2. Runs your logic (loop 100 times, etc)
    3. Fires Event ONCE
]]
function EffectHelpers.withContext(item: any, session: any, callback: (context: any) -> ())
	local ctx = EffectContext.new(item, session)
	if not ctx then return end
	
	callback(ctx)
	
	-- Only fire the signal after all loops are done
	ctx:notifyClient()
end

-- Add rate to all placed items
function EffectHelpers.addRateToAllPlaced(item: any, session: any, amount: number)
	EffectHelpers.withContext(item, session, function(ctx)
		for _, placedItem in ipairs(ctx:getPlacedItems()) do
			-- This is a silent update
			ctx:updateItemRate(placedItem, amount)
		end
	end)
end

-- Add rate to random placed item
function EffectHelpers.addRateToRandomPlaced(item: any, session: any, amount: number)
	EffectHelpers.withContext(item, session, function(ctx)
		local target = ctx:getRandomPlacedItem()
		if target then
			ctx:updateItemRate(target, amount)
		end
	end)
end

-- Add rate to all owned items
function EffectHelpers.addRateToAllOwned(item: any, session: any, amount: number)
	EffectHelpers.withContext(item, session, function(ctx)
		for _, ownedItem in ipairs(ctx:getOwnedItems()) do
			ctx:updateItemRate(ownedItem, amount)
		end
	end)
end

-- Double a random placed item's rate
function EffectHelpers.doubleRandomPlaced(item: any, session: any)
	EffectHelpers.withContext(item, session, function(ctx)
		local target = ctx:getRandomPlacedItem()
		if target then
			ctx:multiplyItemRate(target, 2)
		end
	end)
end

-- Increase own rate (Refactored to use session:GetItem)
function EffectHelpers.increaseSelfRate(item: any, session: any, amount: number)
	EffectHelpers.withContext(item, session, function(ctx)
		-- We use the session to get the "live" version of the item
		local selfItem = ctx.session:GetItem(item.UID)
		if selfItem then
			ctx:updateItemRate(selfItem, amount)
		end
	end)
end

-- Increase own rate only if placed
function EffectHelpers.increaseSelfRateIfPlaced(item: any, session: any, amount: number)
	EffectHelpers.withContext(item, session, function(ctx)
		local selfItem = ctx.session:GetItem(item.UID)
		if selfItem and ctx:isItemPlaced(selfItem) then
			ctx:updateItemRate(selfItem, amount)
		end
	end)
end

return EffectHelpers

-- LEGACY

-- local EffectContext = require(script.Parent.EffectContext)

-- local EffectHelpers = {}

-- -- Wrapper that handles context creation and cleanup
-- function EffectHelpers.withContext(item: any, player: Player, callback: (context: any) -> ())
-- 	local ctx = EffectContext.new(item, player)
-- 	if not ctx then
-- 		warn("⚠️ EffectHelpers: Failed to create context")
-- 		return
-- 	end
-- 	callback(ctx)
-- 	ctx:notifyClient()
-- end

-- -- Add rate to all placed items
-- function EffectHelpers.addRateToAllPlaced(item: any, player: Player, amount: number)
-- 	EffectHelpers.withContext(item, player, function(ctx)
-- 		-- TODO: Collect affected items for visualization
-- 		local affectedItems = {}
-- 		for _, placedItem in ctx:getPlacedItems() do
-- 			ctx:updateItemRate(placedItem, amount)
-- 			-- TODO: table.insert(affectedItems, {UID = placedItem.UID, RateChange = amount})
-- 		end
-- 		-- TODO: ctx:sendEffectVisualization("RateIncrease", affectedItems, string.format("+%d/s → All Placed", amount))
-- 	end)
-- end

-- -- Add rate to random placed item
-- function EffectHelpers.addRateToRandomPlaced(item: any, player: Player, amount: number)
-- 	EffectHelpers.withContext(item, player, function(ctx)
-- 		local target = ctx:getRandomPlacedItem()
-- 		warn("target", target)
-- 		if target then
-- 			ctx:updateItemRate(target, amount)
-- 			-- TODO: ctx:sendEffectVisualization("RateIncrease", {{UID = target.UID, RateChange = amount}}, string.format("+%d/s → Random Item", amount))
-- 		else
-- 			warn("not target")
-- 		end
-- 	end)
-- end

-- -- Add rate to all owned items
-- function EffectHelpers.addRateToAllOwned(item: any, player: Player, amount: number)
-- 	EffectHelpers.withContext(item, player, function(ctx)
-- 		-- TODO: Collect affected items for visualization
-- 		for _, ownedItem in ctx:getOwnedItems() do
-- 			ctx:updateItemRate(ownedItem, amount)
-- 		end
-- 		-- TODO: Send effect visualization
-- 	end)
-- end

-- -- Add rate to random owned item
-- function EffectHelpers.addRateToRandomOwned(item: any, player: Player, amount: number)
-- 	EffectHelpers.withContext(item, player, function(ctx)
-- 		local target = ctx:getRandomOwnedItem()
-- 		if target then
-- 			ctx:updateItemRate(target, amount)
-- 			-- TODO: Send effect visualization
-- 		end
-- 	end)
-- end

-- -- Double a random placed item's rate
-- function EffectHelpers.doubleRandomPlaced(item: any, player: Player)
-- 	EffectHelpers.withContext(item, player, function(ctx)
-- 		local target = ctx:getRandomPlacedItem()
-- 		if target then
-- 			ctx:multiplyItemRate(target, 2)
-- 			-- TODO: ctx:sendEffectVisualization("Multiply", {{UID = target.UID, Multiplier = 2}}, "×2 → Random Item")
-- 		end
-- 	end)
-- end

-- -- Increase own rate (for Growth effects)
-- function EffectHelpers.increaseSelfRate(item: any, player: Player, amount: number)
-- 	EffectHelpers.withContext(item, player, function(ctx)
-- 		if not ctx.playerData then
-- 			local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
-- 			ctx.playerData = PlayerData.Collections[player]
-- 		end

-- 		-- this somehow error idk sometimes
-- 		local selfItem = ctx.playerData:GetItemFromUID(item.UID)
-- 		if selfItem then
-- 			ctx:updateItemRate(selfItem, amount)
-- 		end
-- 	end)
-- end

-- -- Increase own rate only if placed (for conditional Growth effects)
-- function EffectHelpers.increaseSelfRateIfPlaced(item: any, player: Player, amount: number)
-- 	EffectHelpers.withContext(item, player, function(ctx)
-- 		local selfItem = ctx.playerData:GetItemFromUID(item.UID)
-- 		if selfItem and ctx:isItemPlaced(selfItem) then
-- 			ctx:updateItemRate(selfItem, amount)
-- 		end
-- 	end)
-- end

-- -- Add rate to placed items excluding a specific ItemId
-- function EffectHelpers.addRateToPlacedExcluding(item: any, player: Player, amount: number, excludeItemId: string)
-- 	EffectHelpers.withContext(item, player, function(ctx)
-- 		for _, placedItem in ctx:getPlacedItems() do
-- 			if placedItem.ItemId ~= excludeItemId then
-- 				ctx:updateItemRate(placedItem, amount)
-- 			end
-- 		end
-- 	end)
-- end

-- -- Custom effect with full context access
-- function EffectHelpers.customEffect(item: any, player: Player, effectFn: (context: any, item: any) -> ())
-- 	EffectHelpers.withContext(item, player, function(ctx)
-- 		effectFn(ctx, item)
-- 	end)
-- end

-- return EffectHelpers

--[[]
    TODO: Better UX for effect visualization
    
    Problem: Players don't see what's happening when items affect other items.
    - "Random item gets +5/s" - which one?
    - "All placed items get +2/s" - hard to track multiple changes
    - Effects cascade and it's confusing
    
    Solution: Send visual feedback to client showing effect chains
    
    Proposed RemoteEvent structure:
    EffectVisualization:FireClient(player, {
        SourceItem = { UID = "123", ItemId = "Cauldron", Position = Vector3 },
        TargetItems = {
            { UID = "456", ItemId = "Crystal", Position = Vector3, RateChange = 5 },
            { UID = "789", ItemId = "Potion", Position = Vector3, RateChange = 10 }
        },
        EffectType = "RateIncrease", -- or "Multiply", "Synergy", etc.
        Message = "+5/s → All Placed Items" -- Human-readable summary
    })
    
    Client side could show:
    - Particle beam from source → target(s)
    - Floating "+5/s" text above affected items
    - Brief highlight/glow on affected items
    - Toast notification: "Crystal Orb boosted 3 items by +5/s each"
    
    Implementation notes:
    - Add to EffectContext:notifyClient() to collect and send effect data
    - Create new RemoteEvent "EffectVisualization" in RemoteEventsService
    - Build client-side effect renderer (particles, text, beams)
    - Consider batching multiple effects in same tick for performance
]]
