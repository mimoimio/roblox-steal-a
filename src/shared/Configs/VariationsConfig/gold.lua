type VariationsConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond",
	DisplayName: "Copper" | "Silver" | "Gold" | "Diamond"?,
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
}
return {
	VariationId = "gold",
	DisplayName = "Gold",
	Multiplier = 5,
	ColorPrimary = Color3.new(0.827450, 0.894117, 0.239215),
	Weight = 500,
}
