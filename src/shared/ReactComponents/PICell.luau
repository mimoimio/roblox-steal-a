local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local TS = game:GetService("TweenService")
local useToast = require(game.ReplicatedStorage.Shared.ReactComponents.Toasts).useToast
-- Props:
--  UID: string
--  DisplayName: string
--  Height: number? (pixel height) default 50
--  TweenTime: number? default 0.25
--  Children? (additional descendants)

local DEFAULT_TWEEN = 0.25
local MOUNTED_SIZE = UDim2.new(1, 0, 1, 0)
local Size = MOUNTED_SIZE
local function PICell(props: {
	UID: string,
	DisplayName: string,
	LayoutOrder: number,
	clicked: () -> nil,
})
	local frameRef = React.useRef(nil)
	local labelRef = React.useRef(nil)

	return e("Frame", {
		Size = Size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		ref = frameRef,
	}, {
		TextButton = e("TextButton", {
			Size = Size,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			Font = "FredokaOne",
			TextSize = 14,
			Text = props.DisplayName,
			TextColor3 = Color3.new(1, 1, 1),
			ClipsDescendants = true,
			ref = function(textbutton: TextButton)
				if not textbutton then
					return
				end
				textbutton:SetAttribute("UID", props.UID)
			end,
			[React.Event.Activated] = props.clicked,
		}, props.Children),
	})
end

return PICell
