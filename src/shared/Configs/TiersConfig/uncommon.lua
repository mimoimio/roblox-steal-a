type TiersConfig = {
	TierId: "common" | "uncommon" | "rare" | "epic" | "legendary" | "mythic",
	DisplayName: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic",
	ColorPrimary: Color3,
	WorthScale: number,
	ColorSecondary: Color3?,
}

return {
	TierId = "uncommon",
	DisplayName = "Uncommon",
	WorthScale = 2,
	Weight = 30,
	ColorPrimary = Color3.new(0.309803, 0.701960, 0.309803),
}
