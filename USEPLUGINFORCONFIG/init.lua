type ItemConfig = {
	ItemId: string,
	DisplayName: string,
	Rate: number,
	Tier: string,
}

local ItemsConfig: { ItemConfig } = {}
for i, m: ModuleScript in script:GetChildren() do
	assert(m:IsA("ModuleScript"), m.Name .. " IS NOT A MODULE SCRIPT")
	local config = require(m)
	table.insert(ItemsConfig, config)
	ItemsConfig[m.Name] = config
end
return ItemsConfig
