local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local TS = game:GetService("TweenService")
local useToast = require(game.ReplicatedStorage.Shared.ReactComponents.Toasts).useToast

type Item = {
	UID: string, --
	ItemId: string,
	DisplayName: string,
	Rate: number,
}
local DEFAULT_TWEEN = 0.25
local MOUNTED_SIZE = UDim2.new(1, 0, 1, 0)
local Size = MOUNTED_SIZE
local function PICell(props: {
	UID: string,
	Item: Item,
	LayoutOrder: number,
	clicked: () -> nil,
	Selected: boolean,
})
	local frameRef = React.useRef(nil)

	return e("Frame", {
		Size = Size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		ref = frameRef,
		ZIndex = 2,
	}, {
		TextButton = e("TextButton", {
			Size = Size,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = (props.Selected or props.Placed) and 0.4 or 0.9,
			BackgroundColor3 = props.Selected and Color3.new(1, 0, 0)
				or props.Placed and Color3.new(1, 1, 0.6)
				or Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Font = "FredokaOne",
			TextSize = 14,
			Text = props.Item.DisplayName .. "\n" .. props.Item.Rate .. "/s",
			TextColor3 = Color3.new(1, 1, 1),
			ClipsDescendants = true,
			ref = function(textbutton: TextButton)
				if not textbutton then
					return
				end
				textbutton:SetAttribute("UID", props.UID)
			end,
			[React.Event.Activated] = props.clicked,
			ZIndex = 4,
		}, props.Children),
	})
end

return PICell
