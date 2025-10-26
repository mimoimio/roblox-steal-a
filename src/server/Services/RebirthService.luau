local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
local RebirthService = {}

function RebirthService.Rebirth(player: Player)
	local pd = PlayerData.Collections[player]
	pd.Resources.Money = 50
	pd.Progress.Life = pd.Progress.Life and pd.Progress.Life + 1 or 2

	local items = pd.Items
	for i = #items, 1, -1 do
		if not items[i].Reborn then
			items[i] = nil
		end
	end

	pd:FireBEChanged()
	local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
	ItemUpdated:FireClient(player, PlayerData.Collections[player].Items)

	warn("Rebirthed!")
end

return RebirthService
