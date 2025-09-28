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

return {}
