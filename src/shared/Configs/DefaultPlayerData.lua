local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type PlayerData = sharedtypes.PlayerData
type PlayerSettings = sharedtypes.PlayerSettings
type Item = sharedtypes.Item
type ItemSlots = sharedtypes.ItemSlots
type TycoonProps = sharedtypes.TycoonProps

local c = 0
function count()
	c += 1
	return c
end
function generateUID(Player: Player)
	local UID = ("%014X"):format(tick() * 1e4)
	UID = UID:sub(8, UID:len()) .. "_" .. count()
	return UID
end

local DefaultPlayerData = {}

function DefaultPlayerData.Get()
	local DEFAULT_RESOURCES = {
		Money = 50,
		Rate = 0,
	}
	local DEFAULT_SETTINGS = {
		MusicMuted = false,
		MusicVolume = 0.5,
	}
	local DEFAULT_PROGRESS = {
		EXP = 0,
		LVL = 1,
		Life = 1,
	}
	local DEFAULT_ITEMS: { Item } = {
		{
			UID = generateUID(),
			VariationId = "none",
			ItemId = "daybloom",
			DisplayName = "Daybloom",
			TierId = "common",
			Rate = 9,
		},
		{
			UID = generateUID(),
			VariationId = "none",
			ItemId = "daybloom",
			DisplayName = "Daybloom",
			TierId = "common",
			Rate = 9,
		},
	}
	local DEFAULT_ITEMSLOTS: ItemSlots = {
		Slot1 = "none",
		Slot2 = "none",
		Slot3 = "none",
		Slot4 = "none",
		Slot5 = "none",
		Slot6 = "none",
	}
	return {
		Resources = DEFAULT_RESOURCES,
		Collector = 0,
		PlayerSettings = DEFAULT_SETTINGS,
		Progress = DEFAULT_PROGRESS,
		Items = DEFAULT_ITEMS,
		ItemSlots = DEFAULT_ITEMSLOTS,
	}
end

return DefaultPlayerData.Get() :: PlayerData
