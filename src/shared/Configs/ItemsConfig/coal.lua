local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps

return {
	ItemId = "coal",
	DisplayName = "Coal",
	Rate = 3,
	Price = 100,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	ItemTip = [[A lump of coal. No special effects.]],
} :: ItemConfig
