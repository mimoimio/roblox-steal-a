type TiersConfig = {
	TierId: "common" | "uncommon" | "rare" | "epic" | "legendary" | "mythic",
	DisplayName: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic",
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
	WorthScale: number,
}

return {
	TierId = "mythic",
	DisplayName = "Mythic",
	WorthScale = 1,
	Weight = 300,
	ColorPrimary = Color3.new(1, 0.20, 0),
}
