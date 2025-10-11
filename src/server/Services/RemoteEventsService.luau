local Item = require(game.ServerScriptService.Server.Classes.Item)
local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)

local RemoteEventsService = {}

local CreateItem = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
CreateItem.Name = "CreateItem"

local ItemUpdated = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
ItemUpdated.Name = "ItemUpdated"

local GetItems = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
GetItems.Name = "GetItems"

local GetPlayerData = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
GetPlayerData.Name = "GetPlayerData"

local ResourcesUpdated = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
ResourcesUpdated.Name = "ResourcesUpdated"

local StrangeSpawned = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
StrangeSpawned.Name = "StrangeSpawned"

local Wipe = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
Wipe.Name = "Wipe"

function RemoteEventsService.initialize()
	if RemoteEventsService.isInitialized then
		return
	end
	RemoteEventsService.isInitialized = true
	GetPlayerData.OnServerInvoke = function(player)
		return PlayerData.Collections[player]
	end

	GetItems.OnServerInvoke = function(player)
		while not PlayerData.Collections[player] do
			task.wait()
		end
		return PlayerData.Collections[player].Items
	end

	Wipe.OnServerEvent:Connect(function(player) end)
end

return RemoteEventsService
