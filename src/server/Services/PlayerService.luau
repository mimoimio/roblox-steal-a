local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)
local PlayerService = {}

function PlayerService.initialize()
	if PlayerService.isInitialized then
		return
	end
	PlayerService.isInitialized = true
	game:GetService("Players").PlayerAdded:Connect(function(player)
		-- initalizing PlayerData
		PlayerData.new(player)
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		-- saving PlayerData
		PlayerDataService:SavePlayerData(player, PlayerData.Collections[player])
		local pd = PlayerData.Collections[player]
		PlayerData.Owners[pd] = nil
		PlayerData.Collections[player] = nil
	end)
end

return PlayerService
