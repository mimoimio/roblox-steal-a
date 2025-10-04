type TiersConfig = {
	TierId: "common" | "uncommon" | "rare" | "epic" | "legendary" | "mythic",
	DisplayName: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic",
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
	WorthScale: number,
}

return {
	TierId = "legendary",
	DisplayName = "Legendary",
	WorthScale = 8,
	Weight = 180,
	ColorPrimary = Color3.new(0.95, 0.75, 0.1),
}
