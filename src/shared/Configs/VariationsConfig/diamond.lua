type VariationsConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond",
	DisplayName: "Copper" | "Silver" | "Gold" | "Diamond"?,
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
}
return {
	VariationId = "diamond",
	DisplayName = "Diamond",
	Multiplier = 8,
	ColorPrimary = Color3.new(0.015686, 0.592156, 0.858823),
	Weight = 800,
}
