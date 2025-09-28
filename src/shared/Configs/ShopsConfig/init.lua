type ShopConfig = {
	ShopId: string,
	DisplayName: string,
	Dialogues: { [string]: string },
}

local ShopsConfig: { ShopConfig } = {}
for i, m: ModuleScript in script:GetChildren() do
	assert(m:IsA("ModuleScript"), m.Name .. " IS NOT A MODULE SCRIPT")
	ShopsConfig[m.Name] = require(m)
end
return ShopsConfig
