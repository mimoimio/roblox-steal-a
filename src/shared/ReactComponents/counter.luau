local React = require(game.ReplicatedStorage.Packages.React)
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local e = React.createElement

local function Counter(props)
	local exponent, setExponent = React.useState(0)

	return e("TextButton", {
		Name = "CounterButton",
		Text = "10^" .. tostring(exponent) .. ": " .. Alyanum.new(10 ^ exponent):toString(),
		Size = UDim2.new(0, 120, 0, 40),
		BackgroundColor3 = Color3.fromRGB(40, 40, 60),
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.FredokaOne,
		TextSize = 18,
		[React.Event.Activated] = function()
			setExponent(function(prev)
				return prev + 3
			end)
		end,
	})
end

return Counter
