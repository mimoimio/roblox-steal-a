type VariationsConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond",
	DisplayName: "Copper" | "Silver" | "Gold" | "Diamond"?,
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
}
return {
	VariationId = "strange",
	DisplayName = "strange",
	Multiplier = 13,
	ColorPrimary = Color3.new(0.952941, 0.305882, 0.192156),
}
