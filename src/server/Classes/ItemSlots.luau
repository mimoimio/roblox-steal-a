type ItemSlots = { -- contains UID of items from PlayerData.Items
	Slot1: string?,
	Slot2: string?,
	Slot3: string?,
	Slot4: string?,
	Slot5: string?,
	Slot6: string?,
}

local ItemSlots = {}
ItemSlots.__index = ItemSlots
ItemSlots.Collections = {} :: { [Player]: ItemSlots }
local ItemSlotsChanged = Instance.new("BindableEvent")
ItemSlotsChanged.Name = "ItemSlotsChanged"

game.Players.PlayerRemoving:Connect(function(player)
	if ItemSlots.Collections[player] then
		ItemSlots.Owners[ItemSlots.Collections[player]] = nil
		ItemSlots.Collections[player] = nil
	end
end)

ItemSlots.Changed = ItemSlotsChanged.Event
ItemSlots.Owners = {} :: { [ItemSlots]: Player }

function ItemSlots:FireChangedEvent()
	ItemSlotsChanged:Fire(self, ItemSlots.Owners[self])
end

function ItemSlots.new(savedItemSlots: ItemSlots, Player: Player): ItemSlots?
	local self = setmetatable(savedItemSlots, ItemSlots)
	ItemSlots.Owners[self] = Player
	ItemSlots.Collections[Player] = self

	return self
end

return ItemSlots
