local Shop = {}
Shop__index = Shop

function Shop.new()
	local self = setmetatable({}, Shop)
    
	return self
end

return Shop
