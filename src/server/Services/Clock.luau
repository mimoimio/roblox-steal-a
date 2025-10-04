local TweenService = game:GetService("TweenService")
local self = {}

local sunsetBindableEvent = Instance.new("BindableEvent")
self.Sunset = sunsetBindableEvent.Event
local sunriseBindableEvent = Instance.new("BindableEvent")
self.Sunrise = sunriseBindableEvent.Event
local started = false
function self.start()
	if started then
		return
	end
	self.SecondsPerDay = 1 * 30
	self.CurrentTime = game.Lighting.ClockTime
	self.Lights = {}
	for i, d in ipairs(workspace:GetDescendants()) do
		if not d:IsA("Light") then
			continue
		end
		table.insert(self.Lights, d)
	end
	self.IsMorning = game.Lighting.ClockTime >= 7 and game.Lighting.ClockTime < 18 or false
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
		Brightness = 3,
	}):Play()
	for i, light: Light in ipairs(self.Lights) do
		light.Enabled = false
	end
	sunriseBindableEvent:Fire()
end
-- local m = 24
function self.TimeIncrement(dt)
	game.Lighting.ClockTime += dt / self.SecondsPerDay * 24
	-- m += 1
	if game.Lighting.ClockTime >= 7 and game.Lighting.ClockTime < 18 and not self.IsMorning then
		lightsOff()
		self.IsMorning = true
	elseif game.Lighting.ClockTime >= 18 and self.IsMorning then
		lightsOn()
		self.IsMorning = false
	end
end

return self
