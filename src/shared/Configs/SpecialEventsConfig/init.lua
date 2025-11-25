export type SpecialEventsConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond",
	DisplayName: "" | "Copper" | "Silver" | "Gold" | "Diamond",
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
}

local SpecialEventsConfig: { SpecialEventsConfig } = {}
for i, m: ModuleScript in script:GetChildren() do
	assert(m:IsA("ModuleScript"), m.Name .. " IS NOT A SpecialEventsConfig")
	SpecialEventsConfig[m.Name] = require(m)
	table.insert(SpecialEventsConfig, require(m))
end
return SpecialEventsConfig
