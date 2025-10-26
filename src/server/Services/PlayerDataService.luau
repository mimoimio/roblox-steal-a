local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type Item = sharedtypes.Item
type PlayerData = sharedtypes.PlayerData
type ItemConfig = sharedtypes.ItemConfig

local DatastoreService = game:GetService("DataStoreService")
local PlayerDataStore = DatastoreService:GetDataStore("Player")
local DefaultPlayerData = require(game.ReplicatedStorage.Shared.Configs.DefaultPlayerData)

local PlayerDataService = {}

function PlayerDataService:LoadPlayerData(player: Player): PlayerData?
	warn(player.UserId)
	local PlayerData = {}
	local ok: boolean, result: PlayerData?

	for i = 1, 5 do
		ok, result = pcall(function()
			return PlayerDataStore:GetAsync(player.UserId)
		end)
		if ok then
			break
		else
			warn("Failed to load player data:", result, "retrying...")
			task.wait()
		end
	end

	if not ok then
		warn("Critical error: Failed to load player data")
		return nil
	end

	result = result or {}

	local Resources = result.Resources or table.clone(DefaultPlayerData.Resources)
	local Collector: number = result.Collector or DefaultPlayerData.Collector
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
	local ItemSlots = result.ItemSlots or table.clone(DefaultPlayerData.ItemSlots)

	PlayerData = {
		Resources = Resources,
		Collector = Collector,
		PlayerSettings = PlayerSettings,
		Progress = Progress,
		Items = Items,
		ItemSlots = ItemSlots,
	}
	return PlayerData
end

function PlayerDataService:SavePlayerData(player: Player, data: PlayerData)
	-- cleanup functions from datastore
	warn("SAVING")
	for i, c: Item in data.Items do
		c.Entry = nil
		c.Removed = nil
		c.Merged = nil
	end
	warn("After cleaned up funciton")

	local ok, err = pcall(function()
		warn("SAved?")
		warn(PlayerDataStore, PlayerDataStore.SetAsync, player.UserId, data)
		PlayerDataStore:SetAsync(player.UserId, data)
		warn("SAved!")
	end)
	if not ok then
		warn("Failed to SetAsync PlayerData", err)
		warn("PlayerData", data)
		return
	else
		warn("Saved!", data)
	end
end

function onShutdown()
	local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
	for i, player in game.Players:GetPlayers() do
		PlayerDataService:SavePlayerData(player, PlayerData.Collections[player])
	end
end

game:BindToClose(onShutdown)

return PlayerDataService
