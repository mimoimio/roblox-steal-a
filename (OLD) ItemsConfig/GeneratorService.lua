local sharedtypes = require(game.ReplicatedStorage.Shared.types)
local ProfileStore = require(game.ServerScriptService.Server.Services.ProfileStore)
local PlayerSession = require(game.ServerScriptService.Server.Classes.PlayerSession)
type Item = sharedtypes.Item
type TycoonProps = sharedtypes.TycoonProps
type PlayerData = sharedtypes.PlayerData
type ItemConfig = sharedtypes.ItemConfig
type ItemSlots = sharedtypes.ItemSlots
type Slot = sharedtypes.Slot
type Profile = ProfileStore.Profile<PlayerData>
type PlayerSession = PlayerSession.PlayerSession

local PlayerData = require(game.ServerScriptService.Server.Classes.PlayerData)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useRef = React.useRef
local useEffect = React.useEffect
local useState = React.useState

local itemConfigs: { ItemConfig } = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)

local FormatUtil = require(game.ReplicatedStorage.Shared.Utils.Format)
local FormatItemLabelText = FormatUtil.FormatItemLabelText

local PlayerDataService = require(game.ServerScriptService.Server.Services.PlayerDataService)
local PlotService = require(game.ServerScriptService.Server.Services.PlotService)
local Item = require(game.ServerScriptService.Server.Classes.Item)
local MultiplierService = require(game.ServerScriptService.Server.Services.MultiplierService)

local GeneratorService = {}
GeneratorService.Collections = {}

local function OnProfileCreated(playerSession: PlayerSession)
	warn("PROFILE CREATED. STARTING GENERATOR")
	local player = playerSession.Player
	local profile = playerSession.Profile
	local Plot = PlotService.GetPlot(player)

	-- initialize player's generator
	GeneratorService.Collections[player] = {}

	-- setup player's plot
	local function SetUpPlot()
		local ownerBoard = Plot:FindFirstChild("OwnerBoard", true)
		local CollectButton: Part = Plot:FindFirstChild("CollectButton", true)
		if not ownerBoard or not ownerBoard:IsA("Part") then
			return
		end
		local BaseLightAtt: Attachment = game.ReplicatedStorage.Shared:WaitForChild("BaseLightAtt"):Clone()
		BaseLightAtt.Parent = Plot.PrimaryPart
		-- Create SurfaceGui
		local surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Name = "OwnerSurfaceGui"
		surfaceGui.Adornee = ownerBoard
		surfaceGui.Face = Enum.NormalId.Front
		-- surfaceGui.AlwaysOnTop = true
		surfaceGui.Parent = ownerBoard

		-- Create ImageLabel
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Size = UDim2.new(1, 0, 1, 0)
		imageLabel.BackgroundTransparency = 1
		imageLabel.Parent = surfaceGui

		-- Create TextLabel
		local TextLabel = Instance.new("TextLabel")
		TextLabel.Size = UDim2.new(1, 0, 1, 0)
		TextLabel.BackgroundTransparency = 1
		TextLabel.Text = player.Name
		TextLabel.TextScaled = true
		-- TextLabel.TextSize = 100
		TextLabel.Parent = surfaceGui
		TextLabel.Font = Enum.Font.FredokaOne
		TextLabel.ZIndex = 3

		-- Get player thumbnail
		local Players = game:GetService("Players")
		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size420x420
		local thumbUrl, _ = Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)
		imageLabel.Image = thumbUrl

		-- Handling player money collection
		local touchconn = CollectButton.Touched:Connect(function(part)
			local char = part:FindFirstAncestor(player.Name)
			if not char then
				return
			end
			local p = game.Players:GetPlayerFromCharacter(char)
			if not p and p ~= player then
				return
			end
			local profile = PlayerDataService:GetProfile(player)
			if not profile then
				return
			end
			if profile.Data.Collector > 0 then
				game.ReplicatedStorage.Shared.Events.Ping:FireClient(player, "cash")
			else
				return
			end
			profile.Data.Resources.Money += profile.Data.Collector
			profile.Data.Collector = 0
			-- Fire unreliable money/rate update for HUD display
			local MoneyDisplayUpdate = game.ReplicatedStorage.Shared.Events:FindFirstChild("MoneyDisplayUpdate")
			if not MoneyDisplayUpdate then
				MoneyDisplayUpdate = Instance.new("RemoteEvent")
				MoneyDisplayUpdate.Name = "MoneyDisplayUpdate"
				MoneyDisplayUpdate.Parent = game.ReplicatedStorage.Shared.Events
			end
			-- Only send money/rate, not full PlayerData
			MoneyDisplayUpdate:FireClient(player, profile.Data.Resources.Money, profile.Data.Resources.Rate or 0)

			local finalMultiplier = MultiplierService.GetFinalMultiplier(player, "Money")
			local finalRate = math.floor(profile.Data.Resources.Rate * finalMultiplier)
			local sum = profile.Data.Collector + finalRate
			local textlabel = Plot
				and Plot.Collector
				and Plot.Collector:FindFirstChild("CollectDisplay") :: Model
				and Plot.Collector.CollectDisplay:FindFirstChild("SurfaceGui")
				and Plot.Collector.CollectDisplay.SurfaceGui:FindFirstChild("TextLabel")

			local multiplierText = finalMultiplier > 1 and string.format(" (x%.2f)", finalMultiplier) or ""

			if textlabel and textlabel:IsA("TextLabel") then
				textlabel.Text = "Money: "
					.. Alyanum.new(profile.Data.Collector):toString()
					.. "\nRate: "
					.. Alyanum.new(finalRate):toString()
					.. multiplierText
			else
				warn("No textlabel")
			end
			local leaderstats = player:FindFirstChild("leaderstats")
			local Cash = leaderstats.Cash
			Cash.Value = Alyanum.new(profile.Data.Resources.Money):toString()
		end)

		return function()
			if touchconn then
				touchconn:Disconnect()
			end
			if BaseLightAtt then
				BaseLightAtt:Destroy()
			end
			if surfaceGui then
				surfaceGui:Destroy()
			end
			local textlabel = Plot
				and Plot.Collector
				and Plot.Collector:FindFirstChild("CollectDisplay") :: Model
				and Plot.Collector.CollectDisplay:FindFirstChild("SurfaceGui")
				and Plot.Collector.CollectDisplay.SurfaceGui:FindFirstChild("TextLabel")
			if textlabel and textlabel:IsA("TextLabel") then
				textlabel.Text = ""
			else
				warn("No textlabel")
			end
		end
	end
	local CleanUpPlot = SetUpPlot()

	local mounted = false
	local GrowthFunctions = {}

	local function RunGrowth()
		for uid, fn in GrowthFunctions do
			fn()
		end
	end

	--[[
	1. Add offline earnings to the collectors. offline time, limit to 24hrs
	seconds = math.round(math.min( tick() - LastOnline, 24 * 60 * 60 ))
	profile.Data.Collector += profile.Resources.Rate * seconds
	TODO
	]]

	--[[
	2. guard all itemslots make sure itemid actually exist in Data.Items
	if not mounted first time (initialize from datastore) then no need to fire entry
	if exist then get all placed items' growth functions so a Items.ChildAdded will trigger Growth
	]]

	local rate = 0
	local ItemModels: { Model } = {}

	local function Reconcile() --
		local ItemSlots = profile.Data.ItemSlots
		local Items = profile.Data.Items
		local ItemLookup = {}
		local seenUIDs = {} -- any model with UID not in seen in this temporary table are later to be deleted

		for i, item in Items do
			ItemLookup[item.UID] = item
		end

		local threads = {}

		-- Iterate through ItemSlots. Either Update or Create
		for slotnum, UID in ItemSlots do
			local item = ItemLookup[UID]
			if item then
				rate += item.Rate

				-- only do these if this UID has not a rendered Model
				-- 1. Model Rendering
				-- 2. Entry function
				if not ItemModels[UID] then
					-- Model rendering
					local model = game.ReplicatedStorage.Shared.Models:FindFirstChild(item.ItemId):Clone() :: Model
					-- slot model may not be rendered yet so do an async
					table.insert(
						threads,
						task.spawn(function()
							local folder
							local maxRetries = 20
							local retries = 0

							while retries < maxRetries do
								local success, result = pcall(function()
									return workspace:FindFirstChild(player.Name .. "ItemRenderer")
								end)
								if success and result then
									folder = result:FindFirstChild("ItemSlots")
									if folder then
										break
									end
								end
								retries += 1
								warn("Retrying to find", player.Name .. "ItemRenderer")
								task.wait(1)
							end

							if not folder then
								error("Failed to find ItemSlots folder for player: " .. tostring(player.Name))
							end

							local slotsModel: Model = folder:WaitForChild(slotnum) --ItemRenderService.GetPlayerItemSlotModels(props.Player, props.SlotNum)

							local cf, s = slotsModel:GetBoundingBox()
							--slotsModel:FindFirstChildWhichIsA("BasePart", true)

							model:PivotTo(slotsModel)
							model.Parent = workspace
						end)
					)
					ItemModels[UID] = model
					-- calling Entry functions for unentered items.
					local itemconfig = itemConfigs[item.ItemId]
					if not item.Entered then
						if itemconfig.Entry then
							itemconfig.Entry(item, player)
						end
						item.Entered = true
					end
				end
				-- mark UID as seen
				seenUIDs[UID] = true
			else
				-- item may not exist from config deletion
				-- removing missing item
				profile.Data.ItemSlots[slotnum] = "none"
			end
		end

		-- Iterate through ItemModels
		-- If a UID is seen inside seenUIDs
		for UID, model: Model in ItemModels do
			if not seenUIDs[UID] then
				model:Destroy()
				ItemModels[UID] = nil
			end
		end
		profile.Data.Resources.Rate = rate
		profile.Data.Resources.Rate = (profile.Data.Resources.Rate < 1 and profile.Data.Resources.Money < 200) and 1
			or profile.Data.Resources.Rate
		return function()
			for i, thread in threads do
				task.cancel(thread)
			end
		end
	end
	Reconcile()

	--[[
	3. Listen to ItemSlots and Items manipulation to reconcile operations
	]]

	local function SetUpConnections()
		local connections = {
			InventoryChanged = playerSession.InventoryChanged:Connect(function(pathArray, newValue)
				Reconcile()
			end),
			StateChanged = playerSession.StateChanged:Connect(function(pathArray, newValue)
				Reconcile()
			end),
		}
		return function()
			for i, c in connections do
				c:Disconnect()
			end
		end
	end
	local CleanupConnections: () -> nil = SetUpConnections(player)

	local MoneyLoopThread: thread = task.spawn(function()
		while true do
			task.wait(1)
			profile.Data.Collector += profile.Data.Collector
		end
	end)
	local CleanupRenderThreads = function()
		for i, thread: thread in threads do
		end
	end
	GeneratorService.Collections = {
		CleanUpPlot = CleanUpPlot,
		CleanupConnections = CleanupConnections,
		MoneyLoopThread = MoneyLoopThread,
	}
	mounted = true
end
local function OnProfileSessionEnded(player: Player, profile: Profile)
	local Generator = GeneratorService.Collections[player]
	Generator.CleanUpPlot()
	Generator.CleanupConnections()
	task.cancel(Generator.MoneyLoopThread)
	--
end

function GeneratorService.start()
	PlayerDataService.ProfileCreated:Connect(OnProfileCreated)
	PlayerDataService.ProfileSessionEnded:Connect(OnProfileSessionEnded)
end
function GeneratorService.initialize() end
return GeneratorService
