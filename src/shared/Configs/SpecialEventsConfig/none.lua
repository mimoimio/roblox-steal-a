type VariationsConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond",
	DisplayName: "Copper" | "Silver" | "Gold" | "Diamond"?,
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
}
return {
	VariationId = "none",
	DisplayName = "None",
	Multiplier = 1,
	ColorPrimary = Color3.new(0, 0, 0),
	Weight = 1,
}
