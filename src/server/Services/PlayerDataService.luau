local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type Item = sharedtypes.Item
type PlayerData = sharedtypes.PlayerData
type ItemConfig = sharedtypes.ItemConfig

local DatastoreService = game:GetService("DataStoreService")
local PlayerDataStore = DatastoreService:GetDataStore("Player")
local DefaultPlayerData = require(game.ReplicatedStorage.Shared.Configs.DefaultPlayerData)

local PlayerDataService = {}

function PlayerDataService:LoadPlayerData(player: Player)
	warn(player.UserId)
	local PlayerData = {}
	local success, result: PlayerData? = pcall(function()
		return PlayerDataStore:GetAsync(player.UserId)
	end)

	result = success and result or {}

	local Resources = result.Resources or table.clone(DefaultPlayerData.Resources)
	local PlayerSettings = result.PlayerSettings or table.clone(DefaultPlayerData.PlayerSettings)
	local Progress = result.Progress or table.clone(DefaultPlayerData.Progress)
	local Items
	if result.Items then
		Items = result.Items
	else
		Items = {}
		for i, item in DefaultPlayerData.Items do
			table.insert(Items, table.clone(item))
		end
	end
	-- warn("result.ItemSlots", result.ItemSlots)
	-- warn("DefaultPlayerData.ItemSlots", DefaultPlayerData.ItemSlots)
	local ItemSlots = result.ItemSlots or table.clone(DefaultPlayerData.ItemSlots)

	PlayerData = {
		Resources = Resources,
		PlayerSettings = PlayerSettings,
		Progress = Progress,
		Items = Items,
		ItemSlots = ItemSlots,
	}
	return PlayerData
end

function PlayerDataService:SavePlayerData(player: Player, data: PlayerData)
	-- cleanup functions from datastore
	for i, c: Item in data.Items do
		c.Effect = nil
	end

	local success, err = pcall(function()
		PlayerDataStore:SetAsync(player.UserId, data)
	end)
	if not success then
		warn("Failed to SetAsync PlayerData", err)
		warn("PlayerData", data)
		return
	else
		warn("Saved!", data)
	end
end

return PlayerDataService
