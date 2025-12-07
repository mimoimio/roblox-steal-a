local ModelFolder = workspace:WaitForChild("itemfolderRefInstance").Value
if not ModelFolder then
	error("NO ITEMS FOLDER!!!!!!!!!!!")
end

local FurnitureService = {}

local FurnitureConfigs = table.clone(require(game.ServerScriptService.GeneratedItemConfigs))
for i, itemConfig in FurnitureConfigs do
	FurnitureConfigs[itemConfig.ItemId] = itemConfig
end

function FurnitureService:GetConfig(UID: string)
	return FurnitureConfigs[UID]
end

return FurnitureService
