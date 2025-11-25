export type VariationsConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond",
	DisplayName: "" | "Copper" | "Silver" | "Gold" | "Diamond",
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
}

local VariationsConfig: { VariationsConfig } = {}
for i, m: ModuleScript in script:GetChildren() do
	assert(m:IsA("ModuleScript"), m.Name .. " IS NOT A VARIATION CONFIG")
	VariationsConfig[m.Name] = require(m)
	table.insert(VariationsConfig, require(m))
end
return VariationsConfig
