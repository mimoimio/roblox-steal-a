local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps
return {
	ItemId = "dinosaur",
	DisplayName = "The Rigged Creature of All Time",
	Rate = 400,
	Tier = "rare",
} :: ItemConfig
