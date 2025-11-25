local TweenService = game:GetService("TweenService")
local self = {}

local sunsetBindableEvent = Instance.new("BindableEvent")
self.Sunset = sunsetBindableEvent.Event
local sunriseBindableEvent = Instance.new("BindableEvent")
self.Sunrise = sunriseBindableEvent.Event
local started = false

local morningTime = 6.5

function self.start()
	if started then
		return
	end
	self.SecondsPerDay = 8 * 60
	self.CurrentTime = game.Lighting.ClockTime
	self.Lights = {}
	for i, d in ipairs(workspace:GetDescendants()) do
		if not d:IsA("Light") then
			continue
		end
		-- table.insert(self.Lights, d)
	end
	self.IsMorning = game.Lighting.ClockTime >= morningTime and game.Lighting.ClockTime < 18 or false
	if self.IsMorning then
		lightsOff()
	end

	game:GetService("RunService").Heartbeat:Connect(self.TimeIncrement)
	started = true
end

function lightsOn() -- (Sunset)
	TweenService:Create(game.Lighting, TweenInfo.new(1), {
		OutdoorAmbient = Color3.new(0.4, 0.3, 1),
		Brightness = 0,
	}):Play()
	for i, light: Light in ipairs(self.Lights) do
		light.Enabled = true
	end
	sunsetBindableEvent:Fire()
end

function lightsOff() --(Sunrise)
	TweenService:Create(game.Lighting, TweenInfo.new(1), {
		OutdoorAmbient = Color3.new(1, 0.8, 0.5),
		Brightness = 1,
	}):Play()
	for i, light: Light in ipairs(self.Lights) do
		light.Enabled = false
	end
	sunriseBindableEvent:Fire()
end
local minPerGameDay = 20
-- local GameDayPerHour = (1 / minPerGameDay) * 60
-- warn(GameDayPerHour, "GameDayPerHour")
-- local GameWeekPerDay = GameDayPerHour * (1 / 7) / (1 / 24)
-- warn(GameWeekPerDay, "GameWeekPerDay")
-- local GameMonthPerWeek = GameWeekPerDay * (1 / 4) / (1 / 7)
-- warn(GameMonthPerWeek, "GameMonthPerWeek")
local secPerGameHour = minPerGameDay / ((1 / 60) / (1 / 24)) --60 -- s/gH
-- local start = tick()
-- local clockstart = ((tick() / secPerGameHour) % 24)
function self.TimeIncrement(dt)
	local clockNow = (((tick() + 60 * 7) / secPerGameHour) % 24)
	game.Lighting.ClockTime = clockNow
	-- game.Lighting.ClockTime += dt / self.SecondsPerDay * 24
	-- m += 1
	if game.Lighting.ClockTime >= morningTime and game.Lighting.ClockTime < 18 and not self.IsMorning then
		warn("Change to day")
		lightsOff()
		self.IsMorning = true
		if game.Lighting.ClockTime <= 8 then
			local sound = Instance.new("Sound", workspace)
			sound.SoundId = "rbxassetid://4096049827"
			if not sound.IsLoaded then
				sound.Loaded:Wait()
			end
			sound:Play()
			task.delay(sound.TimeLength, function()
				sound:Destroy()
			end)
		end
	elseif ((game.Lighting.ClockTime >= 18) or (game.Lighting.ClockTime < morningTime)) and self.IsMorning then
		warn("Change to night")
		self.IsMorning = false
		lightsOn()
	else
		-- warn("No change")
	end
end

return self
--[[

Clock. Runs the day cycle. A chance to trigger a Special event "Starlight" during the night.
Starlight Event has a chance to turn moonglow to starlit

1 hour irl = 3 in game day cycles
20 minutes = 1 day cycle
10 minutes = 1/2 a day

]]
