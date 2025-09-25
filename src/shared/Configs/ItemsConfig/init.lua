type ItemConfig = {
	ItemId: string,
	DisplayName: string,
	Rate: number,
}

local ItemsConfig: { ItemConfig } = {}
for i, m: ModuleScript in script:GetChildren() do
	assert(m:IsA("ModuleScript"), m.Name .. " IS NOT A MODULE SCRIPT")
	ItemsConfig[m.Name] = require(m)
end
return ItemsConfig
