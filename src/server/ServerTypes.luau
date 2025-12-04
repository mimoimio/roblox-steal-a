local server = game.ServerScriptService.Server
local PlayerDataService = require(server.Services.PlayerDataService)
local RemoteEventsService = require(server.Services.RemoteEventsService)
local TycoonService = require(server.Services.TycoonService)
local ItemRenderService = require(server.Services.ItemRenderService)
local ItemConfigService = require(server.Services.ItemConfigService)
local MultiplierService = require(server.Services.MultiplierService)
local MonetizationService = require(server.Services.MonetizationService)
local Clock = require(server.Services.Clock)
shared = {
	Services = {
		PlayerDataService = PlayerDataService,
		RemoteEventsService = RemoteEventsService,
		MonetizationService = MonetizationService,
		MultiplierService = MultiplierService,
		TycoonService = TycoonService,
		ItemRenderService = ItemRenderService,
		ItemConfigService = ItemConfigService,
		Clock = Clock,
	},
}

export type ServerTypes = typeof(shared)
export type Service = { initialize: () -> nil, start: () -> nil }

return shared
