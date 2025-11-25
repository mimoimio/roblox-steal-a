local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps

return {
	ItemId = "stone",
	DisplayName = "Stone",
	Rate = 1,
	Price = 10,
	TierId = "common",
	Variations = { "none", "copper", "silver", "gold", "diamond", "strange" },
	ItemTip = [[A basic stone. No special effects.]],
} :: ItemConfig
