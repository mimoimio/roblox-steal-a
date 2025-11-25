type VariationsConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond",
	DisplayName: "Copper" | "Silver" | "Gold" | "Diamond"?,
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
}
return {
	VariationId = "copper",
	DisplayName = "Copper",
	Multiplier = 2,
	ColorPrimary = Color3.new(0.639215, 0.388235, 0.388235),
	Weight = 100,
}
