--[[
	Monetization service for handling developer products and gamepasses.
	Updated to use MultiplierService for boost management.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local MultiplierService = require(script.Parent.MultiplierService)
local PlayerDataService = require(script.Parent.PlayerDataService)

local MonetizationService = {}

-- Monetization Configuration
MonetizationService.DeveloperProducts = {
	[3355401894] = {
		Name = "Money Pack Small",
		Price = 25,
		Reward = { Type = "Money", Amount = 1000 },
	},
	[3355402539] = {
		Name = "Money Pack Medium",
		Price = 100,
		Reward = { Type = "Money", Amount = 5000 },
	},
	[1234567892] = {
		Name = "Money Pack Large",
		Price = 250,
		Reward = { Type = "Money", Amount = 15000 },
	},
	[3450086552] = {
		Name = "2x Money Boost (15 Minutes)",
		Price = 75,
		Reward = { Type = "TempBoost", MultiplierId = "2xMoney_Temp", Multiplier = 2, Duration = 900 }, -- 15 mins
	},
}

MonetizationService.GamePasses = {
	[1574431723] = {
		Name = "Permanent 2x Cash",
		MultiplierId = "2xMoney_GamePass",
		Multiplier = 2,
	},
	[12345679] = {
		Name = "Auto Collector",
		Benefits = { "auto_collector" },
	},
}

-- Developer Product Purchase Processing
function MonetizationService.ProcessReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId
	local productData = MonetizationService.DeveloperProducts[productId]

	if not productData then
		warn("[MonetizationService] Unknown product ID:", productId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		warn("[MonetizationService] No profile found for:", player.Name)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Process the reward
	local success = MonetizationService:ProcessReward(player, productData.Reward)

	local pdEvent = game.ReplicatedStorage:FindFirstChild("Shared")
		and game.ReplicatedStorage.Shared.Events:FindFirstChild("PlayerDataUpdated")
	if pdEvent then
		pdEvent:FireClient(player, profile.Data)
	end

	if success then
		print("[MonetizationService] Processed purchase for", player.Name, ":", productData.Name)

		-- Notify client
		local PurchaseSuccess = game.ReplicatedStorage.Shared.Events:FindFirstChild("PurchaseSuccess")
		if PurchaseSuccess then
			PurchaseSuccess:FireClient(player, productData.Name)
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn("[MonetizationService] Failed to process reward for", player.Name)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function MonetizationService:ProcessReward(player, reward)
	local profile = PlayerDataService:GetProfile(player)
	if not profile then
		return false
	end

	if reward.Type == "Money" then
		profile.Data.Resources.Money += reward.Amount

		-- Notify client with flash effect
		local Flash = game.ReplicatedStorage.Shared.Events:FindFirstChild("Flash")
		if Flash and player.Character then
			local pos = player.Character:GetPivot().Position
			Flash:FireClient(player, CFrame.new(pos), "+" .. reward.Amount .. " Money!")
		end

		return true
	elseif reward.Type == "TempBoost" then
		-- Check if player already has this boost active
		local foundMultiplier = MultiplierService.HasActiveMultiplier(player, reward.MultiplierId)
		if foundMultiplier then
			-- Add duration to existing multiplier
			warn(
				string.format(
					"[MonetizationService] %s tried to buy duplicate boost: %s, adding duration instead.",
					player.Name,
					reward.MultiplierId
				)
			)
			return MultiplierService.AddDuration(player, reward.MultiplierId, reward.Duration)
		end
		-- Apply the boost via MultiplierService
		return MultiplierService.AddMultiplier(player, reward.MultiplierId, reward.Multiplier, reward.Duration)
	end

	return false
end

-- Gamepass Management
function MonetizationService:CheckGamePassOwnership(player, gamePassId)
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
	end)

	return success and owns
end

function MonetizationService:ApplyGamePassMultipliers(player)
	for gamePassId, passData in pairs(MonetizationService.GamePasses) do
		if passData.MultiplierId and MonetizationService:CheckGamePassOwnership(player, gamePassId) then
			-- Apply permanent multiplier
			MultiplierService.AddMultiplier(player, passData.MultiplierId, passData.Multiplier, -1)
			print(
				string.format(
					"[MonetizationService] Applied gamepass multiplier '%s' for %s",
					passData.Name,
					player.Name
				)
			)
		end
	end
end

function MonetizationService.GetOwnedGamePasses(player)
	local ownedPasses = {}

	for gamePassId, passData in pairs(MonetizationService.GamePasses) do
		if MonetizationService:CheckGamePassOwnership(player, gamePassId) then
			ownedPasses[gamePassId] = passData
		end
	end

	return ownedPasses
end

function MonetizationService:HasGamePassBenefit(player, benefit)
	for gamePassId, passData in pairs(MonetizationService.GamePasses) do
		if passData.Benefits and table.find(passData.Benefits, benefit) then
			if MonetizationService:CheckGamePassOwnership(player, gamePassId) then
				return true
			end
		end
	end
	return false
end

-- Purchase Prompts
function MonetizationService.PromptProductPurchase(player, productId)
	if not MonetizationService.DeveloperProducts[productId] then
		warn("[MonetizationService] Invalid product ID:", productId)
		return
	end
	print("[MonetizationService] Prompting product purchase for", player.Name, ":", productId)
	-- if PlayerDataService:GetProfile(player)
	MarketplaceService:PromptProductPurchase(player, productId)
end

function MonetizationService.PromptGamePassPurchase(player, gamePassId)
	if not MonetizationService.GamePasses[gamePassId] then
		warn("[MonetizationService] Invalid gamepass ID:", gamePassId)
		return
	end

	MarketplaceService:PromptGamePassPurchase(player, gamePassId)
end

function MonetizationService.OnPromptFinished(userId: number, productId: number, isPurchased: boolean)
	local player = Players:GetPlayerByUserId(userId)
	if not player then
		warn("[MonetizationService] Player not found for userId:", userId)
		return
	end
	if not MonetizationService.DeveloperProducts[productId] then
		warn("[MonetizationService] Invalid product ID:", productId)
		return
	end
	if isPurchased then
		print("[MonetizationService] Product purchase completed for", player.Name, ":", productId)
	end
end

function MonetizationService.OnGamePassPromptFinished(player, gamePassId, wasPurchased)
	if wasPurchased then
		print("[MonetizationService] GamePass purchase completed for", player.Name, ":", gamePassId)

		-- Apply multiplier if this gamepass has one
		local passData = MonetizationService.GamePasses[gamePassId]
		if passData and passData.MultiplierId then
			MultiplierService.AddMultiplier(player, passData.MultiplierId, passData.Multiplier, -1)
		end

		-- Notify client to refresh UI
		local GamePassPurchased = game.ReplicatedStorage.Shared.Events:FindFirstChild("GamePassPurchased")
		if GamePassPurchased then
			GamePassPurchased:FireClient(player, gamePassId)
		end
	end
end

function MonetizationService.initialize()
	task.spawn(function()
		local success, err
		while not success do
			success, err = pcall(function()
				-- Connect marketplace events
				MarketplaceService.ProcessReceipt = MonetizationService.ProcessReceipt

				MarketplaceService.PromptProductPurchaseFinished:Connect(MonetizationService.OnPromptFinished)
				MarketplaceService.PromptGamePassPurchaseFinished:Connect(MonetizationService.OnGamePassPromptFinished)

				-- Setup remote events
				local PurchaseProduct = game.ReplicatedStorage.Shared.Events:FindFirstChild("PurchaseProduct")
				if PurchaseProduct then
					PurchaseProduct.OnServerEvent:Connect(MonetizationService.PromptProductPurchase)
				end

				local PurchaseGamePass = game.ReplicatedStorage.Shared.Events:FindFirstChild("PurchaseGamePass")
				if PurchaseGamePass then
					PurchaseGamePass.OnServerEvent:Connect(MonetizationService.PromptGamePassPurchase)
				end
			end)
			task.wait(1)
		end
		print("[MonetizationService] Initialized")
	end)
end

function MonetizationService.start()
	-- Apply gamepass multipliers to players when they join
	Players.PlayerAdded:Connect(function(player)
		task.wait(2) -- Wait for profile to load
		MonetizationService:ApplyGamePassMultipliers(player)
	end)

	-- Apply to all current players to avoid missing anyone who joined during initialization
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			task.wait(2) -- Wait for profile to load
			MonetizationService:ApplyGamePassMultipliers(player)
		end)
	end
end

return MonetizationService
