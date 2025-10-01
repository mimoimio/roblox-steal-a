local Probability = {}
Probability.__index = Probability

export type Probability = {
	getProbability: () -> number,
	increment: () -> nil,
	reset: () -> nil,
	roll: (self: Probability) -> boolean,
}

function Probability.new(maxCount, maxProb, exponent)
	local self = setmetatable({}, Probability)
	self.overallCount = 0
	self.maxCount = maxCount or 100
	self.maxProb = maxProb or 0.5
	self.exponent = exponent or 5
	return self
end

function Probability:getProbability()
	local ratio = self.overallCount / self.maxCount
	local prob = ratio ^ self.exponent
	return math.min(prob, self.maxProb)
end

function Probability:increment()
	self.overallCount += 1
	-- warn(self.overallCount, "self.overallCount")
end

function Probability:reset()
	self.overallCount = 0
end

function Probability:roll()
	local p = self:getProbability()
	local b = math.random() < p
	if b then
		self:reset()
	end

	return b
end

return Probability
