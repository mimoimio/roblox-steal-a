type TiersConfig = {
	TierId: "common" | "uncommon" | "rare" | "epic" | "legendary" | "mythic",
	DisplayName: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic",
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
	WorthScale: number,
}

return {
	TierId = "epic",
	DisplayName = "Epic",
	WorthScale = 5,
	ColorPrimary = Color3.new(0.5, 0.1, 1),
}
