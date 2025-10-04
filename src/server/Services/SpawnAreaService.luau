local SpawnAreaService = {}

function SpawnAreaService.initialize()
	if SpawnAreaService.isInitialized then
		return
	end
	SpawnAreaService.isInitialized = true
end

return SpawnAreaService
