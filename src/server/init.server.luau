local Events = game.ReplicatedStorage.Shared:WaitForChild("Events")

-- local AddItem = Instance.new("RemoteEvent", Events)
-- AddItem.Name = "AddItem"
-- local RemoveItem = Instance.new("RemoteEvent", Events)
-- RemoveItem.Name = "RemoveItem"
-- local RemoveFirst = Instance.new("RemoteEvent", Events)
-- RemoveFirst.Name = "RemoveFirst"
local PlaceItem = Instance.new("RemoteEvent", Events)
PlaceItem.Name = "PlaceItem"

local SellItems = Instance.new("RemoteEvent", Events)
SellItems.Name = "SellItems"

local ItemSlotsUpdate = Instance.new("RemoteEvent", Events)
ItemSlotsUpdate.Name = "ItemSlotsUpdate"

-- local ItemRenderService = require(script.Services.ItemRenderService)
-- ItemRenderService.new(workspace.Part, AddItem, RemoveItem, RemoveFirst)

local PlayerService = require(script.Services.PlayerService)
PlayerService.initialize()

local RemoteEventsService = require(script.Services.RemoteEventsService)
RemoteEventsService.initialize()

local TycoonService = require(script.Services.TycoonService)
TycoonService.initialize()

local GridService = require(script.Services.GridService)
GridService.initialize()

local TreeSpawnService = require(script.Services.TreeSpawnService)
TreeSpawnService.initialize()

local ItemSpawnService = require(script.Services.ItemSpawnService)
ItemSpawnService.initialize()

local Clock = require(script.Services.Clock)
-- Clock.initialize()
Clock.start()
