type TiersConfig = {
	TierId: "common" | "uncommon" | "rare" | "epic" | "legendary" | "mythic",
	DisplayName: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic",
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
		WorthScale: number,

}

return {
	TierId = "rare",
	DisplayName = "Rare",
	WorthScale = 3,
	ColorPrimary = Color3.new(0.8, 0.4, 0.55),
}
