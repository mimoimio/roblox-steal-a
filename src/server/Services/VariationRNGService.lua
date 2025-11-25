local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type VariationConfig = sharedtypes.VariationConfig
type VariationId = sharedtypes.VariationId
local Probability = require(game.ServerScriptService.Server.Classes.Probability)
local Clock = require(game.ServerScriptService.Server.Services.Clock)
local SpecialEventsService = require(game.ServerScriptService.Server.Services.SpecialEventsService)
type Probability = Probability.Probability
local VariationsConfig = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)

local VariationRNGService = {}
local normalVariaitons = { "none", "copper", "silver", "gold", "diamond", "strange" }

local rollCount = 0

function toggleNightEvent()
	while Clock.IsMorning == nil do
		warn("Waiting for clock to initialize", Clock)
		task.wait()
	end
	if not SpecialEventsService.isInitialized then
		SpecialEventsService.initialize()
	end
	if Clock.IsMorning == true then
		VariationRNGService.Probs["starlight"] = nil
		SpecialEventsService:RemoveEvent("starlight")
		warn("Starlight Events OFF!")
	else
		VariationRNGService.Probs["starlight"] = Probability.new(20, 0.5, 5)
		SpecialEventsService:AddEvent("starlight")
		warn("Starlight Events ON!")
	end
end

function VariationRNGService.initialize()
	if VariationRNGService.isInitialized then
		return
	end
	VariationRNGService.isInitialized = true
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
	Clock.Sunrise:Connect(function()
		toggleNightEvent()
	end)
end

function VariationRNGService:roll(Variations: { VariationId }): VariationConfig
	local varcfg
	local itemVarsDict = {}
	for i, varId in Variations do
		itemVarsDict[varId] = true
	end
	for varId, prob in VariationRNGService.Probs do
		if varId == "none" then
			continue
		end
		if not itemVarsDict[varId] then
			continue
		end

		local count = prob:getProbability()
		local max = prob.maxProb
		-- rolls. If success then use it.
		local roll = prob:roll()
		if roll then
			varcfg = VariationsConfig[varId]
			if varcfg.VariationId == "strange" then
				warn(varcfg.DisplayName, "spawned at count", count, "/", max)
			elseif varcfg.VariationId == "starlight" then
				warn(varcfg.DisplayName, "spawned at count", count, "/", max)
			end
			break
		end
	end
	for varid, probx in VariationRNGService.Probs do
		probx:increment()
	end
	rollCount += 1
	varcfg = varcfg or VariationsConfig["none"]
	warn(varcfg.DisplayName)
	return varcfg
end

return VariationRNGService
