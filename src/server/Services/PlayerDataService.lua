-- src/server/Services/PlayerDataService.luau (Corrected for ProfileStore API)

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Require necessary modules
local ProfileStoreModule = require(game.ServerScriptService.Server.Services.ProfileStore) -- Adjust path if needed
local sharedtypes = require(ReplicatedStorage.Shared.types)
local DefaultPlayerDataConfig = require(ReplicatedStorage.Shared.Configs.DefaultPlayerData)
local Mionum = require(ReplicatedStorage.Packages.Mionum)

-- Define types locally
type Item = sharedtypes.Item
type PlayerData = sharedtypes.PlayerData
type ItemConfig = sharedtypes.ItemConfig
type Profile = ProfileStoreModule.Profile<PlayerData> -- Typed Profile object

-- 2. Define the Profile Template
local PROFILE_TEMPLATE: PlayerData = {
	Resources = DefaultPlayerDataConfig.Resources,
	Collector = DefaultPlayerDataConfig.Collector,
	PlayerSettings = DefaultPlayerDataConfig.PlayerSettings,
	Progress = DefaultPlayerDataConfig.Progress,
	Items = DefaultPlayerDataConfig.Items,
	ItemSlots = {},
	OwnedItems = {},
	UnlockedItems = DefaultPlayerDataConfig.UnlockedItems,
}

-- 3. Create the ProfileStore object using New()
local PlayerProfileStore = ProfileStoreModule.New(
	"Player", -- Your DataStore name
	PROFILE_TEMPLATE
)

-- 4. Cache for active player profiles on this server
local Profiles: { [Player]: Profile } = {}

-- Service module to return
local PlayerDataService = {}

--[[
	Retrieves the currently active Profile for a player on this server.
	Returns nil if the player's data isn't loaded or managed by this server.
]]
function PlayerDataService:GetProfile(player: Player): Profile?
	local startTime = os.clock()
	local timeout = 5 -- seconds

	repeat
		local profile = Profiles[player]
		if profile then
			return profile
		end
		task.wait(0.1)
	until os.clock() - startTime > timeout

	return nil
end

-- [[ --- MODIFIED FUNCTIONS --- ]]

-- LoadPlayerData remains similar, but returns the profile's data table
function PlayerDataService:LoadPlayerData(player: Player): PlayerData?
	local profile = Profiles[player] -- Check if already loaded

	while not profile do
		profile = Profiles[player] -- Check if already loaded
		task.wait()
	end

	return profile.Data

	-- -- If not loaded, attempt to start a session (this part is from the previous example)
	-- local profileKey = tostring(player.UserId)
	-- profile = PlayerProfileStore:StartSessionAsync(profileKey)
	-- warn("profile", profile)
	-- if profile then
	-- 	-- ... (rest of the setup from OnPlayerAdded: AddUserId, Reconcile, Cleanup, ListenToRelease) ...
	-- 	Profiles[player] = profile -- Add to cache
	-- 	return profile.Data -- Return the data table
	-- else
	-- 	player:Kick("Failed to load your data. Please try rejoining.")
	-- 	return nil
	-- end
end

-- SavePlayerData now just releases the profile, saving the cached data automatically
function PlayerDataService:SavePlayerData(player: Player)
	local profile = Profiles[player]
	if profile then
		-- Clean up runtime data *before* releasing
		if profile.Data.Items then
			for _, item: Item in profile.Data.Items do
				item.Entry = nil
				item.Removed = nil
				item.Merged = nil
			end
		end
		-- Release tells ProfileStore to save the profile.Data table
		profile:EndSession()
		warn(`SavePlayerData called: Releasing profile for {player.Name}`)
	else
		warn(`SavePlayerData called for {player.Name}, but no active profile found.`)
	end
end

-- Function to handle when a player joins the game
local function OnPlayerAdded(player: Player)
	local profileKey = tostring(player.UserId) -- Use UserId as the key

	-- Load and session-lock the profile asynchronously
	local profile: Profile? = PlayerProfileStore:StartSessionAsync(profileKey)
	if profile then
		-- Profile successfully loaded and locked!

		-- Add GDPR compliance UserIds (Recommended)
		profile:AddUserId(player.UserId)

		-- Fill in missing data fields from the template
		profile:Reconcile()

		-- Clean up any runtime-only data
		if profile.Data.Items then
			for _, item: Item in profile.Data.Items do
				item.Entry = nil
				item.Removed = nil
				item.Merged = nil
			end
		end

		-- check any removed items in Data.Items
		if profile.Data.Items then
			local ItemsConfig = require(ReplicatedStorage.Shared.Configs.ItemsConfig)
			local validItemIds = {}

			-- Build a set of valid ItemIds
			for _, config in ItemsConfig do
				if config.ItemId then
					validItemIds[config.ItemId] = true
				end
			end

			-- Remove items that don't have a valid config
			local itemsToRemove = {}
			for i, item: Item in profile.Data.Items do
				if not validItemIds[item.ItemId] then
					table.insert(itemsToRemove, i)
					warn(`Removing invalid item {item.ItemId} (UID: {item.UID}) from player {player.Name}'s data`)
				end
			end

			-- Remove in reverse order to maintain indices
			for i = #itemsToRemove, 1, -1 do
				table.remove(profile.Data.Items, itemsToRemove[i])
			end
		end

		-- Store the active profile in the cache
		Profiles[player] = profile

		-- Create leaderboard stats
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		local cash = Instance.new("StringValue")
		cash.Name = "Cash"
		cash.Value = Mionum.new(profile.Data.Resources and profile.Data.Resources.Money or 0):toString()
		cash.Parent = leaderstats

		local Update = Instance.new("BindableEvent")
		Update.Name = "Update"
		Update.Parent = cash
		Update.Event:Connect(function(money: number)
			cash.Value = Mionum.new(money):toString()
		end)

		-- Set up a function to run when the session ends
		-- This replaces ListenToRelease from ProfileService
		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil -- Remove from cache
			warn(`Profile session ended for {player.Name} ({player.UserId})`)
			-- Kick the player to prevent data issues if the session ended unexpectedly
			player:Kick("Your data session has ended. Please rejoin.")
		end)

		-- Now you can access profile.Data table to read/write player data
		-- Example: Let other services know data is ready
		-- game.ServerStorage.PlayerDataLoaded:Fire(player, profile.Data)
	else
		-- The profile couldn't be loaded
		warn(`Critical error: Failed to load profile for {player.Name} ({player.UserId}). Kicking.`)
		player:Kick("Failed to load your data. Please try rejoining the server.")
	end
end

-- Function to handle when a player leaves the game
local function OnPlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile then
		-- End the session - this saves the data and unlocks the session
		profile:EndSession()
		warn(`Ending session profile for {player.Name} ({player.UserId}) on leave.`)
	end
end

-- Function to handle server shutdown
local function OnShutdown()
	warn("Server shutting down. Ending sessions for all active player profiles...")
	local startTime = os.clock()

	-- Iterate through all active profiles and end sessions concurrently
	local threads = {}
	for player, profile in pairs(Profiles) do
		-- Check if the profile session is still active before trying to end it
		if profile:IsActive() then -- IsActive() is still valid
			table.insert(
				threads,
				task.spawn(function()
					profile:EndSession() -- Yields until saved and released
					warn(`Profile session for {player.Name} ended during shutdown.`)
				end)
			)
		end
	end

	-- Wait for all end session threads to complete
	for _, thread in ipairs(threads) do
		task.wait(thread) -- Wait for each coroutine to finish
	end

	local duration = os.clock() - startTime
	warn(`All profile sessions ended. Shutdown process took {string.format("%.2f", duration)} seconds.`)
end

-- playtester
function PlayerDataService:Wipe(player: Player)
	local TycoonService = require(game.ServerScriptService.Server.Services.TycoonService)
	local ItemRenderService = require(game.ServerScriptService.Server.Services.ItemRenderService)
	local MultiplierService = require(game.ServerScriptService.Server.Services.MultiplierService)

	local prevdata = PlayerDataService:GetProfile(player).Data
	if not prevdata then
		return
	end
	if not prevdata.GameCompleted then
		return
	end
	local newItems = {}
	for i, item in DefaultPlayerDataConfig.Items do
		local newitem = table.clone(item)
		newitem.UID = tostring(tick())
		table.insert(newItems, newitem)
	end

	-- Handle RebirthBonus multiplier
	local rebirthBonusValue = 0.05
	if prevdata.Multipliers and prevdata.Multipliers["RebirthBonus"] then
		-- Increment existing RebirthBonus by 0.05
		rebirthBonusValue = prevdata.Multipliers["RebirthBonus"].Value + 0.05
	end

	local soulcrystal = prevdata.Resources.SoulCrystal + 2 + math.floor(math.log(prevdata.Resources.Money, 2))

	local defaultdata = {
		Resources = table.clone(DefaultPlayerDataConfig.Resources),
		Collector = DefaultPlayerDataConfig.Collector,
		PlayerSettings = table.clone(prevdata.PlayerSettings),
		Progress = table.clone(DefaultPlayerDataConfig.Progress),
		Items = {}, --newItems,
		ItemSlots = {},
		OwnedItems = {},
		UnlockedItems = table.clone(DefaultPlayerDataConfig.UnlockedItems),
		Multipliers = prevdata.Multipliers, -- retain bought items, should not just be multipliers actually
		BroomTutorialFinished = prevdata.BroomTutorialFinished,
		TutorialFinished = prevdata.TutorialFinished,
	}

	for name, data in PlayerDataService:GetProfile(player).Data do
		local replacementdata = defaultdata[name]
		PlayerDataService:GetProfile(player).Data[name] = replacementdata
	end

	-- Add/update RebirthBonus multiplier
	MultiplierService.AddMultiplier(player, "RebirthBonus", rebirthBonusValue, -1, "Rebirth Bonus")
	-- Add sourlcrystals
	local pd = PlayerDataService:GetProfile(player).Data
	pd.Resources.SoulCrystal = soulcrystal

	TycoonService.RestartPlayer(player)
	ItemRenderService.RestartPlayer(player)
	local Item = require(game.ServerScriptService.Server.Classes.Item)

	Item.new("daybloom", player)
	Item.new("daybloom", player)

	local leaderstats = player:FindFirstChild("leaderstats")
	local Cash = leaderstats.Cash
	Cash.Update:Fire(pd.Resources.Money)

	game.ReplicatedStorage
		:WaitForChild("Shared")
		:WaitForChild("Events")
		:WaitForChild("PlayerDataUpdated")
		:FireClient(player, PlayerDataService:GetProfile(player).Data)
end

-- Connect Player events
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

-- Bind the shutdown function
game:BindToClose(OnShutdown)

return PlayerDataService
