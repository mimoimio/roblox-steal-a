local React = require(game.ReplicatedStorage.Packages.react)
local e = React.createElement

local function InventorySlots(props: {
	Inventory: { { DisplayName: string } },
})
	local inventorySlots = {
		UIGridLayout = e("UIGridLayout", {
			FillDirectionMaxCells = 3,
			FillDirection = Enum.FillDirection.Horizontal,
			CellSize = UDim2.new(0, 100, 0, 100),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			CellPadding = UDim2.new(0, 4, 0, 8),
		}),
	}
	for i = 1, 9 do
		inventorySlots["slot" .. i] = e("TextButton", {
			key = i,
			LayoutOrder = i,
			BackgroundTransparency = 0,
			Size = UDim2.new(0, 100, 0, 100),
			Text = "",
			TextSize = 42,
			Position = UDim2.new(0, 0, 0, 0),
			ref = function(rbx)
				if rbx then
					props.slotRefs.current[i] = rbx
				else
					props.slotRefs.current[i] = nil
				end
			end,
		}, {
			Padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
		})
	end
	return e("Frame", {
		-- Size = UDim2.new(1, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.new(1, 0, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Active = false,
		ZIndex = 1,
	}, inventorySlots)
end
return InventorySlots
