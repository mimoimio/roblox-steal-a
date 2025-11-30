local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type Item = sharedtypes.Item
export type PlayerData = sharedtypes.PlayerData
type ItemConfig = sharedtypes.ItemConfig

local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)

local ItemSlots = require(game.ServerScriptService.Server.Classes.ItemSlots)
local PlayerSettings = require(game.ServerScriptService.Server.Classes.PlayerSettings)
local ItemsConfig: { ItemConfig } = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
-- local Item = require(game.ServerScriptService.Server.Classes.Item)
--   02:45:30.739  Requested module was required recursively  -  Server - Item:13 do module loader

local PlayerData = {} :: {
	Collections: { [Player]: PlayerData },
	Owners: { [PlayerData]: Player },
}
PlayerData.__index = PlayerData
PlayerData.Collections = {} :: { [Player]: PlayerData }
PlayerData.Owners = {} :: { [PlayerData]: Player }
local Changed = Instance.new("BindableEvent")
PlayerData.Changed = Changed.Event

-- Setup leaderboard updater
Changed.Event:Connect(function(data: PlayerData, player: Player)
	if not player or not player:IsDescendantOf(game.Players) then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local cash = leaderstats:FindFirstChild("Cash")
	if cash and cash:IsA("StringValue") then
		-- cash.Value = Alyanum.new(data and data.Resources and data.Resources.Money or 0):toString()
		cash.Update:Fire(data and data.Resources and data.Resources.Money or 0)
	end
end)

function PlayerData.new(player: Player): PlayerData?
	local savedPD = PlayerDataService:LoadPlayerData(player) -- fetches saved pd or default. nil if DataStore error
	warn("savedPD", savedPD)
	if not savedPD then
		return
	end

	local self = setmetatable(savedPD, PlayerData)
	self.ItemSlots = ItemSlots.new(self.ItemSlots, player)
	self.PlayerSettings = PlayerSettings.new(player, self.PlayerSettings)

	warn(self)

	PlayerData.Owners[self] = player
	PlayerData.Collections[player] = self

	return self
end

function PlayerData:GetItemFromUID(UID: string): Item?
	local pd: PlayerData = self
	local items: { Item } = PlayerDataService:GetProfile(PlayerData.Owners[pd]).Data.Items
	for i, item: Item in items or {} do
		if UID == item.UID then
			return item
		end
	end
	-- warn("NO ITEM", UID, " FOUND IN", pd.Items)
	return
end

function PlayerData:FireREChanged()
	local self: PlayerData = self
	local ItemUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events.ItemUpdated
	ItemUpdated:FireClient(PlayerData.Owners[self], self.Items, true)
end
function PlayerData:FireBEChanged()
	local self: PlayerData = self
	if not self then
		warn("playerData nil")
	end
	Changed:Fire(self, PlayerData.Owners[self])
end

function PlayerData:DeleteItem(UID: string)
	local pd: PlayerData = self
	local items: { Item } = pd.Items
	for i, item: Item in items or {} do
		if UID == item.UID then
			table.remove(items, i)
			pd:FireREChanged()
			return true
		end
	end
end

return PlayerData
