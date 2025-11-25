local ShopService = {}
function ShopService.initialize()
	if ShopService.isInitialized then
		return
	end
	ShopService.isInitialized = true
end
return ShopService
