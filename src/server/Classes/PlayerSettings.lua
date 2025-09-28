local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type PlayerSettings = sharedtypes.PlayerSettings

local PlayerSettings: PlayerSettings = {}
PlayerSettings.__index = PlayerSettings
PlayerSettings.Collections = {}

local Owners: { [{ any }]: Player } = {}

local SetPlayerSettings = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
SetPlayerSettings.Name = "SetPlayerSettings"
SetPlayerSettings.OnServerEvent:Connect(function(player, ps: PlayerSettings)
	PlayerSettings.Collections[player].MusicVolume = ps.MusicVolume
end)

local GetPlayerSettings = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
GetPlayerSettings.Name = "GetPlayerSettings"
GetPlayerSettings.OnServerInvoke = function(player)
	if PlayerSettings.Collections[player] then
		while not PlayerSettings.Collections[player] do
			warn("waiting for the player", player, "'s settings")
			task.wait()
		end
		return PlayerSettings.Collections[player]
	else
		warn("")
	end
end

function PlayerSettings.new(player: Player, savedPlayerSettings: PlayerSettings): PlayerSettings
	local self = setmetatable(savedPlayerSettings, PlayerSettings)

	Owners[self] = player
	PlayerSettings.Collections[player] = self

	return self
end

return PlayerSettings
