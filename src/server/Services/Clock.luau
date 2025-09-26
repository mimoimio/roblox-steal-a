local self = {}

function self.start()
	self.SecondsPerDay = 8 * 60
	self.CurrentTime = game.Lighting.ClockTime
	self.Lights = {}
	for i, d in ipairs(workspace:GetDescendants()) do
		if not d:IsA("Light") then
			continue
		end
		table.insert(self.Lights, d)
	end
	self.IsMorning = game.Lighting.ClockTime >= 7 and game.Lighting.ClockTime < 18
	if self.IsMorning then
		lightsOff()
	end

	game:GetService("RunService").Heartbeat:Connect(self.TimeIncrement)
end

function lightsOn()
	for i, light: Light in ipairs(self.Lights) do
		light.Enabled = true
	end
end

function lightsOff()
	for i, light: Light in ipairs(self.Lights) do
		light.Enabled = false
	end
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
