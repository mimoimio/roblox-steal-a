type VariationsConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond",
	DisplayName: "Copper" | "Silver" | "Gold" | "Diamond"?,
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
}
return {
	VariationId = "silver",
	DisplayName = "Silver",
	Multiplier = 3,
	ColorPrimary = Color3.new(0.349019, 0.552941, 0.588235),
	Weight = 200,
}
