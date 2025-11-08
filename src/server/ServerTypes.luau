local server = game.ServerScriptService.Server
local SpecialEventsService = require(server.Services.SpecialEventsService)
local GridService = require(server.Services.GridService)
local PlayerService = require(server.Services.PlayerService)
local RemoteEventsService = require(server.Services.RemoteEventsService)
local TierRNGService = require(server.Services.TierRNGService)
local VariationRNGService = require(server.Services.VariationRNGService)
local TycoonService = require(server.Services.TycoonService)
local TreeSpawnService = require(server.Services.TreeSpawnService)
local ItemSpawnService = require(server.Services.ItemSpawnService)
local ItemRenderService = require(server.Services.ItemRenderService)
local ItemConfigService = require(server.Services.ItemConfigService)
local MultiplierService = require(server.Services.MultiplierService)
local MonetizationService = require(server.Services.MonetizationService)
local Clock = require(server.Services.Clock)
shared = {
	Services = {
		SpecialEventsService = SpecialEventsService,
		GridService = GridService,
		PlayerService = PlayerService,
		RemoteEventsService = RemoteEventsService,
		TierRNGService = TierRNGService,
		VariationRNGService = VariationRNGService,
		MultiplierService = MultiplierService,
		MonetizationService = MonetizationService,
		TycoonService = TycoonService,
		TreeSpawnService = TreeSpawnService,
		ItemSpawnService = ItemSpawnService,
		ItemRenderService = ItemRenderService,
		ItemConfigService = ItemConfigService,
		Clock = Clock,
	},
}

export type ServerTypes = typeof(shared)
export type Service = { initialize: () -> nil, start: () -> nil }

return shared
