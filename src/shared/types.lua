export type ItemSlots = { [Slot]: string }

export type Slot = "Slot1" | "Slot2" | "Slot3" | "Slot4" | "Slot5" | "Slot6"

export type TycoonProps = {
	Player: Player,
	Plot: Part,
	ItemSlots: ItemSlots,
	Items: { Item },
}

export type VariationId = "none" | "copper" | "silver" | "gold" | "diamond" | "starlight" | "strange"
export type TierId = "common" | "uncommon" | "rare" | "epic" | "legendary" | "mythic"

export type ItemConfig = {
	ItemId: string,
	DisplayName: string,
	Rate: number,
	Tier: string,
	Variations: { VariationId },
	Entry: (item: Item, tycoon: TycoonProps) -> nil?,
	Merge: (item: Item, tycoon: TycoonProps) -> nil?,
	Removed: (item: Item, tycoon: TycoonProps) -> nil?,
}

export type Item = {
	UID: string,
	ItemId: string,
	DisplayName: string,
	VariationId: VariationId,
	Rate: number,
	Entered: boolean?,
}

export type PlayerSettings = { MusicVolume: number? }
export type Progress = { EXP: number, LVL: number, Life: number }
export type PlayerData = {
	Resources: {
		Money: number,
		Rate: number,
	},
	Collector: number,
	PlayerSettings: PlayerSettings,
	Progress: Progress,
	Items: { Item },
	ItemSlots: ItemSlots,
}

export type VariationConfig = {
	VariationId: VariationId,
	DisplayName: string,
	Multiplier: number,
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
	Weight: number,
}
export type TierConfig = {
	TierId: TierId,
	DisplayName: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic",
	ColorPrimary: Color3,
	ColorSecondary: Color3?,
	WorthScale: number,
}

export type SharedTypes = {
	Services: {},
	Classes: {},
}

return {}
