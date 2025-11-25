local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps

return {
	ItemId = "copper",
	DisplayName = "Copper",
	Rate = 8,
	Price = 200,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	ItemTip = [[A chunk of copper. No special effects.]],
} :: ItemConfig
