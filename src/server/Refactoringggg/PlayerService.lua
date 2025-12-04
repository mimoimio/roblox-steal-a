local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type PlayerData = sharedtypes.PlayerData
local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)
local PlayerService = {}
PlayerService.Collections = {} :: { [Player]: PlayerData }

function PlayerService.initialize()
	if PlayerService.isInitialized then
		return
	end
	PlayerService.isInitialized = true

	game:GetService("Players").PlayerAdded:Connect(function(player)
		local pd = PlayerData.new(player)
		if not pd then
			warn("Kicking the player...")
			player:Kick("Datastore fetch error. Kicked to prevent data loss. Sorry!😭😭😭")
			return
		end
		PlayerService.Collections[player] = pd
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		if not PlayerService.Collections[player] then
			return
		end
		PlayerDataService:SavePlayerData(player, PlayerData.Collections[player])
		local pd = PlayerData.Collections[player]
		PlayerData.Owners[pd] = nil
		PlayerData.Collections[player] = nil
		PlayerService.Collections[player] = nil
	end)
end

return PlayerService
