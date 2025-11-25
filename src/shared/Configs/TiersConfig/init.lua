type TiersConfig = {
	TierId: "common" | "uncommon" | "rare" | "epic" | "legendary" | "mythic",
	DisplayName: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic",
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
}

local TiersConfig: { TiersConfig } = {}
for i, m: ModuleScript in script:GetChildren() do
	assert(m:IsA("ModuleScript"), m.Name .. " IS NOT A TIER CONFIG")
	TiersConfig[m.Name] = require(m)
	table.insert(TiersConfig, require(m))
end
return TiersConfig
