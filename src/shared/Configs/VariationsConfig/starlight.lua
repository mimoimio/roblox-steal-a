type VariationsConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond",
	DisplayName: "Copper" | "Silver" | "Gold" | "Diamond"?,
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
}
return {
	VariationId = "starlight",
	DisplayName = "Starlight",
	Multiplier = 6,
	ColorPrimary = Color3.new(0.549019, 0.152941, 1),
	Weight = 200,
}
