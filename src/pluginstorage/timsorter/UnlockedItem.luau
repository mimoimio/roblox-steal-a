--[[
	UnlockedItem Component
	Displays a single unlock with reorder controls
]]

local React = require(script.Parent.Packages.React)
local e = React.createElement

type UnlockedItemProps = {
	unlockId: string,
	displayName: string,
	index: number,
	isSelected: boolean,
	onSelect: () -> (),
	onMoveUp: () -> (),
	onMoveDown: () -> (),
	onGoTo: () -> (),
	onFocus: () -> (),
	canMoveUp: boolean,
	canMoveDown: boolean,
}

local function UnlockedItem(props: UnlockedItemProps)
	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 35),
		BackgroundColor3 = props.isSelected and Color3.fromRGB(70, 70, 120) or Color3.fromRGB(50, 50, 50),
		BorderSizePixel = 0,
		LayoutOrder = props.index,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),

		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}),

		-- Up arrow (only visible when selected and can move up)
		UpArrow = props.isSelected and props.canMoveUp and e("TextButton", {
			Size = UDim2.new(0, 30, 0, 30),
			BackgroundColor3 = Color3.fromRGB(100, 100, 150),
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.SourceSansBold,
			TextSize = 16,
			Text = "↑",
			[React.Event.Activated] = props.onMoveUp,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		}) or e("Frame", {
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
		}),

		-- Main clickable area
		ClickArea = e("TextButton", {
			Size = UDim2.new(1, props.isSelected and -108 or -40, 1, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.SourceSans,
			TextSize = 14,
			Text = string.format("%d. %s", props.index, props.displayName),
			TextXAlignment = Enum.TextXAlignment.Left,
			[React.Event.Activated] = function()
				props.onSelect()
				if props.onFocus then
					props.onFocus()
				end
			end,
		}),

		-- Go To button (always visible)
		GoToButton = e("TextButton", {
			Size = UDim2.new(0, 35, 0, 30),
			BackgroundColor3 = Color3.fromRGB(80, 120, 80),
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.SourceSansBold,
			TextSize = 14,
			Text = "→",
			[React.Event.Activated] = props.onGoTo,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		}),

		-- Down arrow (only visible when selected and can move down)
		DownArrow = props.isSelected and props.canMoveDown and e("TextButton", {
			Size = UDim2.new(0, 30, 0, 30),
			BackgroundColor3 = Color3.fromRGB(100, 100, 150),
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.SourceSansBold,
			TextSize = 16,
			Text = "↓",
			[React.Event.Activated] = props.onMoveDown,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		}) or e("Frame", {
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
		}),
	})
end

return UnlockedItem
