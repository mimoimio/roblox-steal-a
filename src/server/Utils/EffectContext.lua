--[[
	EffectContext: Centralizes data access for item effects
	Provides a unified interface to player data, items, and slots
]]

export type EffectContext = {
	item: any,
	player: Player,

	-- Helper methods
	getProfileData: (self: EffectContext) -> any?,
	getPlacedItems: (self: EffectContext) -> { any },
	getOwnedItems: (self: EffectContext) -> { any },
	getRandomPlacedItem: (self: EffectContext) -> any?,
	getRandomOwnedItem: (self: EffectContext) -> any?,
	isItemPlaced: (self: EffectContext, item: any) -> boolean,
	updateItemRate: (self: EffectContext, targetItem: any, delta: number) -> (),
	multiplyItemRate: (self: EffectContext, targetItem: any, multiplier: number) -> (),
	notifyClient: (self: EffectContext) -> (),
}

local EffectContext = {}
EffectContext.__index = EffectContext

local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)

function EffectContext.new(item: any, player: Player): EffectContext?
	if not player then
		warn("⚠️ EffectContext: No player")
		return
	end
	if not item then
		warn("⚠️ EffectContext: No item")
		return
	end

	-- Verify profile exists
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warn("⚠️ EffectContext: No profile found for", player.Name)
		return nil
	end

	local self = setmetatable({}, EffectContext)
	self.item = item
	self.player = player

	return self
end

-- Helper function to get fresh profile data
function EffectContext:getProfileData(): any?
	local profile = PlayerDataService:GetProfile(self.player)
	if not profile then
		warn("⚠️ EffectContext: Profile not found for", self.player.Name)
		return nil
	end
	return profile.Data
end

-- Get all placed items
function EffectContext:getPlacedItems(): { any }
	local pd = self:getProfileData()
	if not pd then
		return {}
	end

	local placed = {}
	for slot, UID in pd.ItemSlots do
		if UID and UID ~= "none" then
			-- Find item in Items array by UID
			for _, item in pd.Items do
				if item.UID == UID then
					table.insert(placed, item)
					break
				end
			end
		end
	end
	return placed
end

-- Get all owned items (in inventory)
function EffectContext:getOwnedItems(): { any }
	local pd = self:getProfileData()
	if not pd then
		return {}
	end
	return pd.Items or {}
end

-- Get a random placed item
function EffectContext:getRandomPlacedItem(): any?
	local placed = self:getPlacedItems()
	if #placed == 0 then
		return nil
	end
	return placed[math.random(1, #placed)]
end

-- Get a random owned item
function EffectContext:getRandomOwnedItem(): any?
	local pd = self:getProfileData()
	if not pd then
		return nil
	end

	local items = pd.Items or {}
	if #items == 0 then
		return nil
	end
	return items[math.random(1, #items)]
end

-- Check if an item is placed
function EffectContext:isItemPlaced(checkItem: any): boolean
	local pd = self:getProfileData()
	if not pd then
		return false
	end

	for slot, UID in pd.ItemSlots do
		if UID == checkItem.UID then
			return true
		end
	end
	return false
end

-- Update an item's rate by adding a delta
function EffectContext:updateItemRate(targetItem: any, delta: number)
	targetItem.Rate += delta
end

-- Multiply an item's rate
function EffectContext:multiplyItemRate(targetItem: any, multiplier: number)
	targetItem.Rate *= multiplier
end

-- Fire all necessary update events to sync client
function EffectContext:notifyClient()
	local pd = self:getProfileData()
	if not pd then
		warn("⚠️ EffectContext: Cannot notify client - no profile data")
		return
	end

	local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
	ItemUpdated:FireClient(self.player, pd.Items)

	local ItemSlots = require(game.ServerScriptService.Server.Classes.ItemSlots)
	ItemSlots.FireChangedEvent(pd.ItemSlots, self.player)

	-- Update display
	local MoneyDisplayUpdate: UnreliableRemoteEvent = game.ReplicatedStorage.Shared.Events.MoneyDisplayUpdate
	MoneyDisplayUpdate:FireClient(self.player, pd.Resources.Money, pd.Resources.Rate)
end

return EffectContext
