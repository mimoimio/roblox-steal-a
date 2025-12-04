local RewardService = {}
RewardService.__index = RewardService

local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type PlayerData = sharedtypes.PlayerData

local Item = require(game.ServerScriptService.Server.Classes.Item)
local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)

function RewardService.start()
	-- Setup ProcessReward event handler
	local Events = game.ReplicatedStorage.Shared.Events
	local ProcessReward = Events:FindFirstChild("ProcessReward")
	if not ProcessReward then
		ProcessReward = Instance.new("RemoteEvent")
		ProcessReward.Name = "ProcessReward"
		ProcessReward.Parent = Events
	end

	ProcessReward.OnServerEvent:Connect(function(player: Player, slotNum: string, itemId: string)
		local pd = PlayerData.Collections[player]
		if not pd then
			warn("[RewardService] PlayerData not found for", player.Name)
			return
		end

		-- Check if reward exists for this slot
		if not pd.Rewards or not pd.Rewards[slotNum] then
			warn("[RewardService] No rewards found for slot", slotNum)
			return
		end

		local rewardChoices = pd.Rewards[slotNum]
		local isValidChoice = false
		for _, rewardItemId in ipairs(rewardChoices) do
			if rewardItemId == itemId then
				isValidChoice = true
				break
			end
		end

		if not isValidChoice then
			warn("[RewardService] Invalid reward choice", itemId, "for slot", slotNum)
			return
		end

		-- Create the item
		local success = Item.new(itemId, player)
		if success then
			-- Clear the reward for this slot
			pd.Rewards[slotNum] = nil

			-- If no more rewards, clear the Rewards table
			local hasRewards = false
			for _ in pairs(pd.Rewards) do
				hasRewards = true
				break
			end
			if not hasRewards then
				pd.Rewards = nil
			end

			print("[RewardService] Player", player.Name, "claimed reward", itemId, "for slot", slotNum)
		else
			warn("[RewardService] Failed to create item", itemId, "for player", player.Name)
		end
	end)
end

return RewardService
