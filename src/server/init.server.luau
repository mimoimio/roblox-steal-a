local Events = game.ReplicatedStorage.Shared:WaitForChild("Events")

local AddItem = Instance.new("RemoteEvent", Events)
AddItem.Name = "AddItem"

local RemoveItem = Instance.new("RemoteEvent", Events)
RemoveItem.Name = "RemoveItem"

local RemoveFirst = Instance.new("RemoteEvent", Events)
RemoveFirst.Name = "RemoveFirst"

local PlaceItem = Instance.new("RemoteEvent", Events)
PlaceItem.Name = "PlaceItem"

local SellItems = Instance.new("RemoteEvent", Events)
SellItems.Name = "SellItems"

local SellItem = Instance.new("RemoteEvent", Events)
SellItem.Name = "SellItem"

local ItemSlotsUpdate = Instance.new("RemoteEvent", Events)
ItemSlotsUpdate.Name = "ItemSlotsUpdate"

local ServerTypes = require(script.ServerTypes)
type Service = ServerTypes.Service
local shared: { Services: { Service } } = ServerTypes
for _, service in shared.Services do
	if service.initialized then
		continue
	end
	if service.initialize then
		local ok, err = pcall(service.initialize, service)
		if not ok then
			warn("Error initializing service:", err)
		end
	end
end

-- Start phase
for _, service in shared.Services do
	if service.start then
		local ok, err = pcall(service.start, service)
		if not ok then
			warn("Error starting service:", err)
		end
	end
end
