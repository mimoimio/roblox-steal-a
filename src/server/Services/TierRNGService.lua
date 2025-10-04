local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type TierConfig = sharedtypes.TierConfig
local Probability = require(game.ServerScriptService.Server.Classes.Probability)
local Clock = require(game.ServerScriptService.Server.Services.Clock)
type Probability = Probability.Probability
local TiersConfig = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)

local TierRNGService = {}
local normalTiers = { "common", "uncommon", "rare", "epic", "legendary", "mythic" }

function TierRNGService.initialize()
	if TierRNGService.isInitialized then
		warn("initializing more once")
		return
	end
	TierRNGService.isInitialized = true

	TierRNGService.Probs = {} :: { Probability }
	for i, tierId in normalTiers do
		local tiercfg: TierConfig = TiersConfig[tierId]
		TierRNGService.Probs[tiercfg.TierId] = Probability.new(tiercfg.Weight)
	end
	warn("Initialized")
end

function TierRNGService:roll(): TierConfig
	local tiercfg
	if not TierRNGService.isInitialized then
		warn("NOT YET INITIALIZED")
	end
	for tierId, prob in TierRNGService.Probs do
		if tierId == "common" then
			continue
		end
		local count = prob:getProbability()
		local max = prob.maxProb
		local roll = prob:roll()
		for tierId, probx in TierRNGService.Probs do
			probx:increment()
		end
		if roll then
			tiercfg = TiersConfig[tierId]
			break
		end
	end
	-- warn(tiercfg or TiersConfig["common"])
	return tiercfg or TiersConfig["common"]
end

return TierRNGService
