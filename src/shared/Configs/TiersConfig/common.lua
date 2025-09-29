type TiersConfig = {
	TierId: "common" | "uncommon" | "rare" | "epic" | "legendary" | "mythic",
	DisplayName: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic",
	WorthScale: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
}

return {
	TierId = "common",
	DisplayName = "Common",
	WorthScale = 1,
	ColorPrimary = Color3.new(1, 1, 1),
}
