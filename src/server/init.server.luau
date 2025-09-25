local Events = game.ReplicatedStorage.Shared:WaitForChild("Events")

-- local AddItem = Instance.new("RemoteEvent", Events)
-- AddItem.Name = "AddItem"
-- local RemoveItem = Instance.new("RemoteEvent", Events)
-- RemoveItem.Name = "RemoveItem"
-- local RemoveFirst = Instance.new("RemoteEvent", Events)
-- RemoveFirst.Name = "RemoveFirst"
local PlaceItem = Instance.new("RemoteEvent", Events)
PlaceItem.Name = "PlaceItem"

-- local ItemRenderService = require(script.Services.ItemRenderService)
-- ItemRenderService.new(workspace.Part, AddItem, RemoveItem, RemoveFirst)

local PlayerService = require(script.Services.PlayerService)
PlayerService.initialize()

local EventsService = require(script.Services.EventsService)
EventsService.initialize()

local TycoonService = require(script.Services.TycoonService)
TycoonService.initialize()

local GridService = require(script.Services.GridService)
GridService.initialize()

local ItemSpawnService = require(script.Services.ItemSpawnService)
ItemSpawnService.initialize()
