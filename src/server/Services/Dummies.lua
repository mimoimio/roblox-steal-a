local ModelFolder = workspace:WaitForChild("itemfolderRefInstance").Value
if not ModelFolder then
	error("NO ITEMS FOLDER!!!!!!!!!!!")
end

type IC = {}

local ItemConfigs: { IC } = require(game.ServerScriptService.GeneratedItemConfigs)
local ICLookup: {
	[string]: { Config: IC, Index: number },
} = {
	Remove = function(self, ItemId: string)
		local IC = self[ItemId]
		if not IC then
			return
		end
		local config = IC.Config
		local index = IC.Index

		table.remove(ItemConfigs, index)
		for i = index, #ItemConfigs do
			self[ItemConfigs[i].ItemId].Index = i
		end
	end,
}
-- this should be used in the plugin, for quick lookup when adding and removing ICs

--filling ICLookup with reference to configs
for i, ic in ItemConfigs do
	ICLookup[ic.ItemId] = {
		Config = ic,
		Index = i,
	}
end

--remove item from ICLookup
local function Remove(ItemId: string) end

for i, itemConfig in ItemConfigs do
	ItemConfigs[itemConfig.ItemId] = itemConfig
end

local PlayerData = {
	Cash = 200,
	Rate = 0,
	UnlockedItems = {
		[ItemConfigs[1].ItemId] = true,
	},
	OwnedItems = {},
}

return {
	ItemConfigs = ItemConfigs,
	ModelFolder = ModelFolder,
	PlayerData = PlayerData,
	ICLookup = ICLookup,
	OriginalBase = workspace.OriginalBase.Value,
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
		return workspace.Button.Value:Clone()
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
