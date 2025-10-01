export type ItemSlots = { [Slot]: string }

export type Slot = "Slot1" | "Slot2" | "Slot3" | "Slot4" | "Slot5" | "Slot6"

export type TycoonProps = {
	Player: Player,
	Plot: Part,
	ItemSlots: ItemSlots,
	Items: { Item },
}

export type ItemConfig = {
	ItemId: string,
	DisplayName: string,
	Rate: number,
	Tier: string,
}

export type Item = {
	UID: string,
	ItemId: string,
	DisplayName: string,
	Rate: number,
}

export type PlayerSettings = { MusicVolume: number? }

export type PlayerData = {
	Resources: { [string]: number },
	PlayerSettings: PlayerSettings,
	Progress: { EXP: number, LVL: number },
	Items: { Item },
	ItemSlots: ItemSlots,
}

export type VariationConfig = {
	VariationId: "none" | "copper" | "silver" | "gold" | "diamond" | "strange",
	DisplayName: "" | "Copper" | "Silver" | "Gold" | "Diamond",
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
	Weight: number,
}
export type TierConfig = {
	TierId: "common" | "uncommon" | "rare" | "epic" | "legendary" | "mythic",
	DisplayName: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic",
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
	WorthScale: number,
}

return {}
