local self = {}
local SpecialEvents = Instance.new("RemoteEvent", game.ReplicatedStorage.Shared.Events)
SpecialEvents.Name = "SpecialEvents"
local GetSpecialEvents = Instance.new("RemoteFunction", game.ReplicatedStorage.Shared.Events)
GetSpecialEvents.Name = "GetSpecialEvents"

function self.initialize()
	if self.isInitialized then
		return
	end
	self.Events = {} :: { [string]: boolean }
	GetSpecialEvents.OnServerInvoke = function()
		return self.Events
	end
	self.isInitialized = true
end
function self:AddEvent(eventId: string)
	self.Events[eventId] = true
	SpecialEvents:FireAllClients(self.Events)
end
function self:RemoveEvent(eventId: string)
	self.Events[eventId] = nil
	SpecialEvents:FireAllClients(self.Events)
end

return self
