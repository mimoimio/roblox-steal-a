--[[
	ItemConfigService: Provides information about available item configurations
]]

local ServerScriptService = game:GetService("ServerScriptService")

local ItemConfigService = {}

local totalItemCount = 0

function ItemConfigService.initialize()
	-- Count all items in the GeneratedItemConfigs module
	local configModule = ServerScriptService:FindFirstChild("GeneratedItemConfigs")
	if configModule then
		local success, configs = pcall(function()
			return require(configModule)
		end)

		if success and typeof(configs) == "table" then
			totalItemCount = #configs
			print("✅ ItemConfigService: Counted", totalItemCount, "total items")
		else
			warn("⚠️ ItemConfigService: Failed to load GeneratedItemConfigs")
			totalItemCount = 0
		end
	else
		warn("⚠️ ItemConfigService: GeneratedItemConfigs module not found")
		totalItemCount = 0
	end
end

function ItemConfigService.getTotalItemCount(): number
	return totalItemCount
end

return ItemConfigService
