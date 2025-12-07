local ShopSystem = {}

-- CONFIG
local SMALL_CYCLE_DURATION = 4 * 60 -- 5 mins hour
local CYCLES_PER_BIG_CYCLE = 6

function ShopSystem.getCurrentState()
	local currentTime = os.time() -- UTC Timestamp

	-- The unique ID for the current shop rotation
	local currentSmallSeed = math.floor(currentTime / SMALL_CYCLE_DURATION)

	-- Where we are in the big rotation (1 to 5)
	-- The % operator gives us 0-4, so we add 1
	local currentPosition = (currentSmallSeed % CYCLES_PER_BIG_CYCLE) + 1

	local isSpecialEvent = (currentPosition == CYCLES_PER_BIG_CYCLE)

	return {
		seed = currentSmallSeed,
		position = currentPosition,
		isSpecial = isSpecialEvent,
		timeLeft = ((currentSmallSeed + 1) * SMALL_CYCLE_DURATION) - currentTime,
	}
end

function ShopSystem.generateItems()
	local state = ShopSystem.getCurrentState()

	-- KEY PART: Seeding the RNG
	-- Because we use the time-based seed, every server returns the same result
	local rng = Random.new(state.seed)

	print("Cycle Position: " .. state.position .. "/5")

	if state.isSpecial then
		print("!!! 5TH CYCLE SPECIAL EVENT ACTIVE !!!")
		-- Logic for special crafting variance
	end

	-- Shop Logic
	local shopItems = {
		Item1 = rng:NextInteger(1, 100), -- Example item ID
		Item2 = rng:NextInteger(1, 100),
	}

	return shopItems
end

return ShopSystem
