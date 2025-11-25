local Item = require(game.ServerScriptService.Server.Classes.Item)
local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)

local RemoteEventsService = {}

local CreateItem = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
CreateItem.Name = "CreateItem"

local ItemUpdated = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
ItemUpdated.Name = "ItemUpdated"

local GetItems = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
GetItems.Name = "GetItems"

local GetPlayerData = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
GetPlayerData.Name = "GetPlayerData"

local GetTotalItemCount = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
GetTotalItemCount.Name = "GetTotalItemCount"

local ResourcesUpdated = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
ResourcesUpdated.Name = "ResourcesUpdated"

local StrangeSpawned = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
StrangeSpawned.Name = "StrangeSpawned"

-- local ShowNpcDialogue = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
-- ShowNpcDialogue.Name = "ShowNpcDialogue"

local FinishTutorial = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
FinishTutorial.Name = "FinishTutorial"

local FinishBroomTutorial = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
FinishBroomTutorial.Name = "FinishBroomTutorial"

local MultipliersUpdated = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
MultipliersUpdated.Name = "MultipliersUpdated"

local GetMultipliers = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
GetMultipliers.Name = "GetMultipliers"

-- Monetization RemoteEvents
local PurchaseProduct = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
PurchaseProduct.Name = "PurchaseProduct"

local PurchaseGamePass = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
PurchaseGamePass.Name = "PurchaseGamePass"

local PurchaseSuccess = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
PurchaseSuccess.Name = "PurchaseSuccess"

local PurchaseFailed = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
PurchaseFailed.Name = "PurchaseFailed"

local GamePassPurchased = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
GamePassPurchased.Name = "GamePassPurchased"

local BuyItem = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
BuyItem.Name = "BuyItem"

local Wipe: RemoteEvent = game.ReplicatedStorage.Shared:WaitForChild("Events").Wipe

function RemoteEventsService.initialize()
	if RemoteEventsService.isInitialized then
		return
	end
	local folder = game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("ItemsConfig")
	local itemConfigs: {} = {}
	local itemConfigById: {} = {}

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("ModuleScript") then
			local config = require(child)
			table.insert(itemConfigs, config)
			itemConfigById[config.ItemId] = config
		end
	end

	BuyItem.OnServerEvent:Connect(function(player: Player, ItemId: string)
		local itemconfig = itemConfigById[ItemId]
		if not itemconfig then
			warn("no item by", ItemId)
			return
		end
		local pd = PlayerDataService:GetProfile(player).Data
		if not pd then
			warn("no player")
			return
		end

		local money = pd.Resources.Money
		money -= itemconfig.Price
		if money <= 0 then
			return
		end
		if not Item.new(itemconfig.ItemId, player) then
			return
		end

		pd.Resources.Money = money
		local MoneyDisplayUpdate: UnreliableRemoteEvent =
			game.ReplicatedStorage.Shared.Events:WaitForChild("MoneyDisplayUpdate")
		MoneyDisplayUpdate:FireClient(player, pd.Resources.Money, pd.Resources.Rate)
	end)

	RemoteEventsService.isInitialized = true
	GetPlayerData.OnServerInvoke = function(player)
		local profile = PlayerDataService:GetProfile(player)
		return profile and profile.Data
	end

	GetItems.OnServerInvoke = function(player)
		local profile = PlayerDataService:GetProfile(player)
		while not profile do
			task.wait()
			profile = PlayerDataService:GetProfile(player)
		end
		return PlayerDataService:GetProfile(player).Data.Items
	end

	GetTotalItemCount.OnServerInvoke = function(player)
		local ItemConfigService = require(game.ServerScriptService.Server.Services.ItemConfigService)
		return ItemConfigService.getTotalItemCount()
	end

	Wipe.OnServerEvent:Connect(function(player)
		local pds = require(game.ServerScriptService.Server.Services.PlayerDataService)
		pds:Wipe(player)
	end)

	-- Handle tutorial completion from client
	FinishTutorial.OnServerEvent:Connect(function(player)
		local profile = PlayerDataService:GetProfile(player)
		if profile then
			profile.Data.TutorialFinished = true
			-- Notify client of updated player data if an event exists
			local pdEvent = game.ReplicatedStorage:FindFirstChild("Shared")
				and game.ReplicatedStorage.Shared.Events:FindFirstChild("PlayerDataUpdated")
			if pdEvent then
				pdEvent:FireClient(player, profile.Data)
			end
			warn("Player", player.Name, "finished tutorial")
		end
	end)

	-- Handle broomstick tutorial completion from client
	FinishBroomTutorial.OnServerEvent:Connect(function(player)
		local profile = PlayerDataService:GetProfile(player)
		if profile then
			profile.Data.BroomTutorialFinished = true
			-- Notify client of updated player data
			local pdEvent = game.ReplicatedStorage:FindFirstChild("Shared")
				and game.ReplicatedStorage.Shared.Events:FindFirstChild("PlayerDataUpdated")
			if pdEvent then
				pdEvent:FireClient(player, profile.Data)
			end
			print(string.format("[BroomTutorial] Player %s completed broomstick tutorial", player.Name))
		end
	end)

	-- Handle multiplier requests from client
	GetMultipliers.OnServerInvoke = function(player)
		local MultiplierService = require(game.ServerScriptService.Server.Services.MultiplierService)
		return MultiplierService.GetMultipliers(player)
	end
end

return RemoteEventsService
