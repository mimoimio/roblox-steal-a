local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type VariationConfig = sharedtypes.VariationConfig
local Probability = require(game.ServerScriptService.Server.Classes.Probability)
local Clock = require(game.ServerScriptService.Server.Services.Clock)
type Probability = Probability.Probability
local VariationsConfig = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)

local VariationRNGService = {}
local normalVariaitons = { "none", "copper", "silver", "gold", "diamond", "strange" }

function toggleNightEvent()
	while Clock.IsMorning == nil do
		warn("Waiting for clock to initialize", Clock)
		task.wait()
	end
	if Clock.IsMorning == true then
		VariationRNGService.Probs["starlight"] = nil
		warn("Starlight Events OFF!")
	elseif Clock.IsMorning == false then
		VariationRNGService.Probs["starlight"] = Probability.new(20, 0.5, 5)
		warn("Starlight Events ON!")
	end
end

function VariationRNGService.initialize()
	Clock.start()
	VariationRNGService.Probs = {} :: { Probability }
	for i, varid in normalVariaitons do
		local varcfg: VariationConfig = VariationsConfig[varid]
		VariationRNGService.Probs[varcfg.VariationId] = Probability.new(varcfg.Weight)
	end
	toggleNightEvent()
	Clock.Sunset:Connect(function()
		toggleNightEvent()
	end)
end

function VariationRNGService:roll(): VariationConfig
	local varcfg
	for varId, prob in VariationRNGService.Probs do
		if varId == "none" then
			continue
		end
		local count = prob:getProbability()
		local max = prob.maxProb
		local roll = prob:roll()
		for varid, probx in VariationRNGService.Probs do
			probx:increment()
		end
		if roll then
			varcfg = VariationsConfig[varId]
			warn(VariationsConfig, varId)
			warn(varcfg.DisplayName, "spawned at count", count, "/", max)
			break
		end
	end
	return varcfg or VariationsConfig["none"]
end

return VariationRNGService
