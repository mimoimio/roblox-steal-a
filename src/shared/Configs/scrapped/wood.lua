local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps

return {
	ItemId = "wood",
	DisplayName = "Wood",
	Rate = 1,
	Price = 15,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	ItemTip = [[A piece of wood. No special effects.]],
} :: ItemConfig
