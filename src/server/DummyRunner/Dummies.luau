local ModelFolder = workspace.OriginalBase:FindFirstChild("Items") or workspace:FindFirstChild("Items")
if not ModelFolder then
	error("NO ITEMS FOLDER!!!!!!!!!!!")
end

local ItemConfigs = require(game.ServerScriptService.GeneratedItemConfigs)

for i, itemConfig in ItemConfigs do
	ItemConfigs[itemConfig.ItemId] = itemConfig
end

local PlayerData = {
	Cash = 50,
	Rate = 2,
	UnlockedItems = {
		["floor"] = true,
	},
	OwnedItems = {},
}

return {
	ItemConfigs = ItemConfigs,
	ModelFolder = ModelFolder,
	PlayerData = PlayerData,
	OriginalBase = workspace.OriginalBase,
	GetModelFromItemId = function(self, ItemId: string)
		local model = ModelFolder:FindFirstChild(ItemId)
		-- warn("Getting", ItemId)
		if model then
			-- warn("Done")
			return model:Clone(), true
		else
			task.spawn(function()
				error("!!!NO MODEL FOUND!!!" .. ItemId)
			end)
			return workspace.Error:Clone(), false
		end
	end,
	GetButton = function()
		return workspace.Button:Clone()
	end,
	GetItemFromItemId = function(self, ItemId: string)
		for i, itemConfig in ItemConfigs do
			if itemConfig.ItemId ~= ItemId then
				continue
			end
			return itemConfig
		end
	end,
}
