local React = require(game.ReplicatedStorage.Packages.react)
local e = React.createElement
local function ShopSlots(props: {
	Item1: string,
	Item2: string,
	Item3: string,
})
	-- shopSlots with 3 slots, each containing an Item
	local shopSlots = {
		UIGridLayout = e("UIGridLayout", {
			FillDirectionMaxCells = 3,
			FillDirection = Enum.FillDirection.Horizontal,
			CellSize = UDim2.new(0, 100, 0, 100),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			CellPadding = UDim2.new(0, 4, 0, 8),
		}),
	}
	for i = 1, 3 do
		shopSlots["slot" .. i] = e("Frame", {
			key = i,
			LayoutOrder = i,
			BackgroundTransparency = 0.8,
			Size = UDim2.new(0, 100, 0, 100),
		}, {}) -- Item rendered separately on overlay
	end

	return e("Frame", {
		Size = UDim2.new(0, 320, 0, 120),
		Position = UDim2.new(0, 0, 1, -120),
		AnchorPoint = Vector2.new(0, 1),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 0.2,
		BackgroundColor3 = Color3.new(1, 0, 0),
		ZIndex = 2,
	}, shopSlots)
end
return ShopSlots
