local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps
return {
	ItemId = "radiooze",
	DisplayName = "Radioactive Ooze",
	Rate = 200,
	Tier = "uncommon",
} :: ItemConfig
