local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps

return {
	ItemId = "iron",
	DisplayName = "Iron",
	Rate = 10,
	Price = 800,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	ItemTip = [[A chunk of iron. ]],
} :: ItemConfig
