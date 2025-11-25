local PlayerDataService = require(script.Parent.PlayerDataService)

local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type PlayerData = sharedtypes.PlayerData
type Multiplier = sharedtypes.Multiplier

local MultiplierService = {}
MultiplierService.isInitialized = false

--[[
	Adds or updates a multiplier for a player.
	@param player Player - The player to add multiplier to
	@param multiplierId string - Unique ID for this multiplier (e.g., "2xMoney_Temp", "2xMoney_GamePass")
	@param value number - The multiplier value (e.g., 2 for 2x)
	@param duration number - Duration in seconds (use -1 for permanent)
	@return boolean - Success status
]]
function MultiplierService.AddMultiplier(
	player: Player,
	multiplierId: string,
	value: number,
	duration: number,
	DisplayName: string
): boolean
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warn("[MultiplierService] No profile found for player:", player.Name)
		return false
	end

	-- Initialize Multipliers table if it doesn't exist
	if not profile.Data.Multipliers then
		profile.Data.Multipliers = {}
	end

	local expireTime = duration == -1 and -1 or (tick() + duration)

	profile.Data.Multipliers[multiplierId] = {
		DisplayName = DisplayName or multiplierId,
		Value = value,
		Expire = expireTime,
	}

	-- Fire event to client
	local MultipliersUpdated = game.ReplicatedStorage.Shared.Events:FindFirstChild("MultipliersUpdated")
	if MultipliersUpdated then
		MultipliersUpdated:FireClient(player, profile.Data.Multipliers)
	end

	print(
		string.format(
			"[MultiplierService] Added multiplier '%s' (x%d) for %s. Expires: %s",
			multiplierId,
			value,
			player.Name,
			duration == -1 and -1 and "Never" or string.format("in %.0f seconds", duration)
		)
	)

	return true
end

--[[
	Removes a specific multiplier from a player.
	@param player Player
	@param multiplierId string
	@return boolean - Success status
]]
function MultiplierService.RemoveMultiplier(player: Player, multiplierId: string): boolean
	local profile = PlayerDataService:GetProfile(player)
	if not profile or not profile.Data.Multipliers then
		return false
	end

	if profile.Data.Multipliers[multiplierId] then
		profile.Data.Multipliers[multiplierId] = nil

		-- Fire event to client
		local MultipliersUpdated = game.ReplicatedStorage.Shared.Events:FindFirstChild("MultipliersUpdated")
		if MultipliersUpdated then
			MultipliersUpdated:FireClient(player, profile.Data.Multipliers)
		end

		print(string.format("[MultiplierService] Removed multiplier '%s' for %s", multiplierId, player.Name))
		return true
	end

	return false
end

--[[
	Adds duration to an existing multiplier.
	@param player Player
	@param multiplierId string
	@param additionalDuration number - Duration in seconds to add
	@return boolean - Success status
]]
function MultiplierService.AddDuration(player: Player, multiplierId: string, additionalDuration: number): boolean
	local profile = PlayerDataService:GetProfile(player)
	if not profile or not profile.Data.Multipliers then
		return false
	end

	local multiplier = profile.Data.Multipliers[multiplierId]
	if not multiplier then
		return false
	end

	-- Don't add duration to permanent multipliers
	if multiplier.Expire == -1 then
		warn(string.format("[MultiplierService] Cannot add duration to permanent multiplier '%s'", multiplierId))
		return false
	end

	-- Add the duration
	multiplier.Expire = multiplier.Expire + additionalDuration

	-- Fire event to client
	local MultipliersUpdated = game.ReplicatedStorage.Shared.Events:FindFirstChild("MultipliersUpdated")
	if MultipliersUpdated then
		MultipliersUpdated:FireClient(player, profile.Data.Multipliers)
	end

	print(
		string.format(
			"[MultiplierService] Added %.0f seconds to multiplier '%s' for %s",
			additionalDuration,
			multiplierId,
			player.Name
		)
	)

	return true
end

--[[
	Checks if a player has a specific active multiplier.
	Automatically cleans up expired multipliers.
	@param player Player
	@param multiplierId string
	@return boolean - True if player has this active multiplier
]]
function MultiplierService.HasActiveMultiplier(player: Player, multiplierId: string): boolean | Multiplier
	local profile = PlayerDataService:GetProfile(player)
	if not profile or not profile.Data.Multipliers then
		return false
	end

	local multiplier = profile.Data.Multipliers[multiplierId]
	if not multiplier then
		return false
	end

	-- Check if expired
	if multiplier.Expire ~= -1 and tick() >= multiplier.Expire then
		-- Expired, remove it
		MultiplierService.RemoveMultiplier(player, multiplierId)
		return false
	end

	return profile.Data.Multipliers[multiplierId]
end

--[[
	Gets the final multiplier for a player by multiplying all active multipliers.
	Automatically cleans up expired multipliers.
	@param player Player
	@param multiplierType string - Optional type filter (currently unused, for future expansion)
	@return number - Final multiplier value (1.0 if no multipliers)
]]
function MultiplierService.GetFinalMultiplier(player: Player, multiplierType: string?): number
	local profile = PlayerDataService:GetProfile(player)
	if not profile or not profile.Data.Multipliers then
		return 1
	end

	MultiplierService.CleanupExpired(player)

	local finalMultiplier = 0
	for multiplierId, multiplier in pairs(profile.Data.Multipliers) do
		-- print("multiplierId, multiplier", multiplierId, multiplier)
		finalMultiplier = finalMultiplier + multiplier.Value
	end

	if finalMultiplier < 1 then
		return 1 + finalMultiplier
	else
		return finalMultiplier
	end
end

--[[
	Cleans up all expired multipliers for a player.
	@param player Player
	@return number - Count of removed multipliers
]]
function MultiplierService.CleanupExpired(player: Player): number
	local profile = PlayerDataService:GetProfile(player)
	if not profile or not profile.Data.Multipliers then
		return 0
	end

	local currentTime = tick()
	local removedCount = 0
	local toRemove = {}

	-- Collect expired multipliers
	for multiplierId, multiplier in pairs(profile.Data.Multipliers) do
		if multiplier.Expire ~= -1 and currentTime >= multiplier.Expire then
			table.insert(toRemove, multiplierId)
		end
	end

	-- Remove expired multipliers
	for _, multiplierId in ipairs(toRemove) do
		profile.Data.Multipliers[multiplierId] = nil
		removedCount = removedCount + 1
		-- print(string.format("[MultiplierService] Expired multiplier '%s' for %s", multiplierId, player.Name))
	end

	-- Notify client if any were removed
	if removedCount > 0 then
		local MultipliersUpdated = game.ReplicatedStorage.Shared.Events:FindFirstChild("MultipliersUpdated")
		if MultipliersUpdated then
			MultipliersUpdated:FireClient(player, profile.Data.Multipliers)
		end
	end

	return removedCount
end

--[[
	Gets all active multipliers for a player (after cleanup).
	@param player Player
	@return { [string]: Multiplier } - Table of active multipliers
]]
function MultiplierService.GetMultipliers(player: Player): { [string]: Multiplier }
	local profile = PlayerDataService:GetProfile(player)
	if not profile or not profile.Data.Multipliers then
		return {}
	end

	MultiplierService.CleanupExpired(player)
	return profile.Data.Multipliers
end

--[[
	Initializes the MultiplierService.
	Sets up periodic cleanup loop.
	Note: RemoteEvents are created in RemoteEventsService
]]
function MultiplierService.initialize()
	if MultiplierService.isInitialized then
		return
	end
	MultiplierService.isInitialized = true

	-- Periodic cleanup loop (every 30 seconds)
	task.spawn(function()
		while true do
			task.wait(30)
			for _, player in ipairs(game.Players:GetPlayers()) do
				local removed = MultiplierService.CleanupExpired(player)
				if removed > 0 then
					print(
						string.format(
							"[MultiplierService] Cleaned up %d expired multipliers for %s",
							removed,
							player.Name
						)
					)

					-- Fire updated multipliers to client after cleanup
					local MultipliersUpdated = game.ReplicatedStorage.Shared.Events:FindFirstChild("MultipliersUpdated")
					if MultipliersUpdated then
						local profile = PlayerDataService:GetProfile(player)
						if profile then
							MultipliersUpdated:FireClient(player, profile.Data.Multipliers or {})
						end
					end
				end
			end
		end
	end)

	print("[MultiplierService] Initialized")
end

return MultiplierService
