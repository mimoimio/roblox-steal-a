local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)

local function TopRightHud(props)
	local money = props.money
	local rate = props.rate

	-- State to force re-render every second
	local tick_state, setTickState = React.useState(0)

	-- Update every second to refresh the expiration timers
	React.useEffect(function()
		local running = true
		task.spawn(function()
			while running do
				task.wait(1)
				setTickState(tick_state + 1)
			end
		end)
		return function()
			running = false
		end
	end, {})

	-- Calculate total multiplier
	local totalMult = 1
	for multId, multData in pairs(props.multipliers) do
		if multData.Value then
			totalMult = totalMult * multData.Value
		end
	end

	-- Build money and rate display
	local moneyText = "Money: " .. (money and Alyanum.new(money):toString() or "...")
	local rateText = "\nRate: " .. ((Alyanum.new(totalMult * rate):toString() .. "/s") or "...")

	if totalMult > 1 and rate then
		rateText = rateText
			.. string.format(
				"\n" .. [[<font color="#FFD700" size="12">(%s × %.1fx)</font>]],
				Alyanum.new(rate):toString(),
				totalMult
			)
	end

	-- Build multipliers list with expiration times
	local multipliersText = ""
	if next(props.multipliers) then
		multipliersText = "\n\nMultipliers:"
		for multId, multData in pairs(props.multipliers) do
			local value = multData.Value or 1
			local expire = multData.Expire or 0
			if expire > 1 or expire == math.huge then
				local timeLeft = math.max(0, expire - tick())
				local minutes = math.floor(timeLeft / 60)
				local seconds = math.floor(timeLeft % 60)

				multipliersText = multipliersText
					.. string.format(
						"\n" .. [[<font color="#00FF88">%.1fx (%02d:%02d)</font>]],
						value,
						minutes,
						seconds
					)
			else
				multipliersText = multipliersText
					.. string.format("\n" .. [[<font color="#00FF88">%.1fx (permanent)</font>]], value)
			end
		end
	end

	return e("ImageLabel", {
		Name = "TopRightHud",
		Image = "rbxassetid://136242854116857",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(30, 30, 90, 90),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
		}),
		verticallist = e(require(script.Parent.ui.verticallist)),
		TextLabel = e("TextLabel", {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Font = "FredokaOne",
			TextSize = 14,
			TextStrokeTransparency = 0,
			Text = moneyText .. rateText .. multipliersText,
			RichText = true,
			Active = false,
			TextColor3 = Color3.new(1, 1, 1),
		}),
	})
end

return TopRightHud
