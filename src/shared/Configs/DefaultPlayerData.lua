type PlayerData = {
	Resources: { [string]: number },
	PlayerSettings: { MusicVolume: number },
	Progress: { EXP: number, LVL: number },
	Items: {
		{
			UID: string,
			ItemId: string,
			DisplayName: string,
			Rate: number,
		}
	},
	ItemSlots: { -- contains UID of items from PlayerData.Items
		Slot1: string?,
		Slot2: string?,
		Slot3: string?,
		Slot4: string?,
		Slot5: string?,
		Slot6: string?,
	},
}

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
	}
	local DEFAULT_SETTINGS = {
		MusicMuted = false,
		MusicVolume = 0.5,
	}
	local DEFAULT_PROGRESS = {
		EXP = 0,
		LVL = 1,
	}
	local DEFAULT_ITEMS = {
		{
			UID = generateUID(),
			ItemId = "stick",
			DisplayName = "Stick",
			Rate = 2,
		},
		{
			UID = generateUID(),
			ItemId = "rock",
			DisplayName = "Rock",
			Rate = 3,
		},
	}
	local DEFAULT_ITEMSLOTS = {
		Slot1 = "none",
		Slot2 = "none",
		Slot3 = "none",
		Slot4 = "none",
		Slot5 = "none",
		Slot6 = "none",
	}
	return {
		Resources = DEFAULT_RESOURCES,
		PlayerSettings = DEFAULT_SETTINGS,
		Progress = DEFAULT_PROGRESS,
		Items = DEFAULT_ITEMS,
		ItemSlots = DEFAULT_ITEMSLOTS,
	}
end

return DefaultPlayerData.Get() :: PlayerData
