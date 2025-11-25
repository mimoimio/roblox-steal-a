type Item = {
	UID: string, --
	ItemId: string,
	DisplayName: string,
	Rate: number,
}
local PICell = require(script.Parent.PICell)
local rounded = require(script.Parent.ui.rounded)

local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef
local useState = React.useState

type Slot = "Slot1" | "Slot2" | "Slot3" | "Slot4" | "Slot5" | "Slot6"

type ItemViewportProps = {
	ItemId: string,
	Size: UDim2?,
	BackgroundTransparency: number?,
}
local function PlaceItem(props: {
	Items: { Item },
	PlaceItemOpen: boolean,
	clicked: (() -> nil)?,
	PlaceSlot: Slot,
	close: () -> nil,
	PlacedItemUids: {},
})
	local Items: { Item } = props.Items or {}

	local children = {
		UIPadding = e("UIPadding", {
			PaddingRight = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 16),
		}),
		UIListLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalFlex = Enum.UIFlexAlignment.None,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
			Padding = UDim.new(0, 8),
			VerticalAlignment = "Bottom",
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	local SFRef = useRef()
	local childNum = 0

	for i, item in Items do
		childNum += 1
		children["item" .. item.UID] = e(PICell, {
			key = item.UID,
			UID = item.UID,
			Item = item,
			Rate = item.Rate,
			LayoutOrder = i,
			clicked = props.clicked,
			Placed = (function()
				return props.PlacedItemUids[item.UID]
			end)(),
		}, {
			rounded = e(rounded),
		})
	end

	local FrameRef = useRef()
	local SFRef = useRef()

	return e("ImageLabel", {
		Size = UDim2.new(1, 0, 0, 240),
		Position = UDim2.new(0.5, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.new(0, 0.2, 0.2),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = false,
		Visible = props.PlaceItemOpen,
		ref = FrameRef,
		ClipsDescendants = false,
		ZIndex = 1,
		Image = "rbxassetid://136242854116857",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(30, 30, 90, 90),
	}, {
		-- Title
		Title = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 40),
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0.5, 0, 0, -40),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Font = "FredokaOne",
			TextSize = 32,
			Text = "💐PLACE ITEM" .. " (" .. (props.PlaceSlot or "no slot chosen") .. ")",
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0,
			ZIndex = 2,
		}),

		UIGradient = e("UIGradient", {
			Color = ColorSequence.new(
				Color3.new(0.458823, 0.168627, 0.270588),
				Color3.new(0.133333, 0.058823, 0.384313)
			),
		}),
		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
		}),
		ScrollingFrame = e("ScrollingFrame", {
			ScrollingDirection = Enum.ScrollingDirection.X,
			Size = UDim2.new(1, 0, 1, -0),
			Position = UDim2.new(0, 0, 0, 0),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			-- BackgroundColor3 = Color3.new(1, 0, 0),
			ref = SFRef,
			Active = false,
			ZIndex = 2,
			ClipsDescendants = true,
			ScrollBarThickness = 16,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
		}, children),
		CloseButton = e("TextButton", {
			-- AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(0, 42, 0, 42),
			BorderSizePixel = 0,
			Text = "X",
			Font = "FredokaOne",
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.new(1, 0.2, 0.4),
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 42,
			ZIndex = 10,
			[React.Event.Activated] = props.close,
			Position = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			Rounded = e(require(script.Parent.ui.rounded)),
		}),
		-- TextLabel = e("TextLabel", {
		-- 	AutomaticSize = Enum.AutomaticSize.XY,
		-- 	Position = UDim2.new(0.5, 0, 0, 0),
		-- 	AnchorPoint = Vector2.new(0.5, 1),
		-- 	BackgroundTransparency = 0.9,
		-- 	BorderSizePixel = 0,
		-- 	Font = "FredokaOne",
		-- 	TextSize = 20,
		-- 	Text = "PLACE ITEM: " .. (props.PlaceSlot or ""),
		-- 	TextColor3 = Color3.new(1, 1, 1),
		-- 	TextStrokeColor3 = Color3.new(0, 0, 0),
		-- 	TextStrokeTransparency = 0,
		-- }),
	})
end

return PlaceItem
