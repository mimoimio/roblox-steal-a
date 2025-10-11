local React = require(game.ReplicatedStorage.Packages.React)
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local useToast = require(script.Parent.Toasts).useToast

type Item = {
	UID: string, --
	ItemId: string,
	DisplayName: string,
	Rate: number,
}

local someTable = {
	Key1 = "Value1",
	Key2 = "Value2",
	Key3 = "Value3",
	Key4 = "Value4",
}

local OPEN_POS = UDim2.new(0.5, 0, 0.5, 0)

local function test(props: {})
	local toast = useToast()
	local someState, setSomeState = useState(0)
	local count = Alyanum.fromScientific("1e" .. someState)

	local someRef = useRef(someTable)
	useEffect(function()
		toast.open("10^" .. someState .. " = " .. tostring(count))
	end, { count })

	return e("TextButton", {
		Size = UDim2.new(0, 200, 0, 200),
		Position = OPEN_POS,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(0, 0.2, 0.2),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Text = "Multiply x10",
		TextColor3 = Color3.new(1, 1, 1),
		[React.Event.Activated] = function()
			-- setSomeState(function(prev)
			-- 	local a = prev
			-- 	a += 1e10
			-- 	return a
			-- end)
			if not someRef.current then
				return
			end
		end,
		ClipsDescendants = false,
		ZIndex = 100,
	})
end

return test
