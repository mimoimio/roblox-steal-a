local React = require(script.Parent.Packages.React)
local ItemVisualizer = require(script.Parent.ItemVisualizer)
local e = React.createElement

local function ItemListUI(props: {
	MasterItemConfig: {},
})
	local children = {
		UIListLayout = e("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalFlex = "Fill",
		}),
		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}),
	}

	for i, itemConfig in props.MasterItemConfig or {} do
		children[itemConfig.ItemId] = e(ItemVisualizer, {
			key = itemConfig.ItemId,
			itemConfig = itemConfig,
			i = i,
		})
	end
	return e("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(136, 169, 241),
		AutomaticCanvasSize = Enum.AutomaticSize.XY,
		-- ref = function(sf: ScrollingFrame?) end,
	}, children)
end

return ItemListUI
