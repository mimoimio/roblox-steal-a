local TextService = game:GetService("TextService")

local textsize = require(script.Parent.textsize)
local ItemViewport = require(script.Parent.ItemViewport)
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local TiersConfig = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)

-- Helper component for inventory item card matching shop item card layout
local function InventoryItem(props: {
	itemConfig: any,
	itemId: string,
	Item: any,
	UID: string,
	Rate: number,
	Placed: boolean?,
	Selected: string?,
	OnSelect: (any) -> (),
	sell: (any) -> (),
	index: number,
})
	local itemTip = props.itemConfig.ItemTip
	local tier = TiersConfig[props.itemConfig.TierId]

	return e("TextButton", {
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		-- AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(0, 150, 0, 150),
		ZIndex = 2,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Text = "",
		[React.Event.Activated] = props.OnSelect,
	}, {
		Color = e("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1)),
			-- Color = ColorSequence.new(tier.ColorPrimary, tier.ColorSecondary or tier.ColorPrimary),
			Rotation = 45,
		}),

		rounded = e(require(script.Parent.ui.rounded)),
		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 20),
		}),
		ItemImage = e(ItemViewport, {
			ItemId = props.itemId,
			BackgroundTransparency = 1,
			ZIndex = 3,
			Size = UDim2.new(1, 0, 1, 0),
			LayoutOrder = 1,
		}),
		InfoContainer = props.Selected == props.UID and e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 0.4,
			ZIndex = 4,
			LayoutOrder = 2,
		}, {
			Rounded = e(require(script.Parent.ui.rounded)),
			verticallist = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				VerticalFlex = Enum.UIFlexAlignment.SpaceBetween,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
			InfoContainer = e("Frame", {
				-- Size = UDim2.new(0, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				ZIndex = 4,
				LayoutOrder = 2,
			}, {
				verticallist = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					-- VerticalFlex = Enum.UIFlexAlignment.SpaceBetween,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				ItemTip = itemTip and e("TextLabel", {
					TextStrokeTransparency = 0,
					LayoutOrder = 5,
					BackgroundTransparency = 1,
					Font = "FredokaOne",
					RichText = true,
					Text = itemTip:gsub("\n", " "),
					TextColor3 = Color3.fromRGB(200, 200, 200),
					TextWrapped = true,
					TextYAlignment = Enum.TextYAlignment.Top,
					ZIndex = 3,
					AutomaticSize = Enum.AutomaticSize.Y,
				}, {
					UITextSizeConstraint = e(textsize, { Min = 14, Max = 14 }),
				}),
			}),

			SellButton = props.Selected == props.UID and e("TextButton", {
				ZIndex = 3,
				BackgroundColor3 = Color3.new(0.807843, 0.141176, 0.141176),
				TextStrokeTransparency = 0,
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				LayoutOrder = 6,
				Font = "FredokaOne",
				TextSize = 14,
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = "Sell",
				TextColor3 = Color3.new(1, 1, 1),
				Active = true,
				[React.Event.Activated] = function()
					props.sell({ Name = props.UID })
				end,
			}, {
				rounded = e(require(script.Parent.ui.rounded)),
				UIPadding = e("UIPadding", {
					PaddingTop = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
					PaddingLeft = UDim.new(0, 8),
					PaddingBottom = UDim.new(0, 8),
				}),
			}),
		}),
		bg = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0,
			ZIndex = 2,
			LayoutOrder = 2,
		}, {
			Rounded = e(require(script.Parent.ui.rounded)),
			Color = e("UIGradient", {
				Color = props.Placed and ColorSequence.new(Color3.new(0, 1, 0.2), Color3.new(0, 0.6, 0.4))
					or ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.6, 0.7, 0.8)),
				Rotation = 45,
			}),
		}),
		ItemName = e("TextLabel", {
			TextStrokeTransparency = 0,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = "FredokaOne",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 0),
			RichText = true,
			Position = UDim2.new(0, 0, 0, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Text = (
				(props.Item.Entered and "" or "*")
				.. (props.itemConfig.DisplayName or props.itemId)
				.. "\n"
				.. "<font size='14'>"
				.. TiersConfig[props.itemConfig.TierId].DisplayName
				.. "</font>"
			),
			TextColor3 = TiersConfig[props.itemConfig.TierId].ColorPrimary or Color3.new(1, 1, 1),
			TextWrapped = true,
			ZIndex = 4,
		}, {
			UITextSizeConstraint = e(textsize, { Min = 14, Max = 16 }),
		}),
		RateLabel = e("TextLabel", {
			BackgroundTransparency = 1,
			TextStrokeTransparency = 0,
			LayoutOrder = 0,
			Position = UDim2.new(0, 0, 1, 0),
			AnchorPoint = Vector2.new(0, 0),
			Size = UDim2.new(1, 0, 0, 0),
			Font = "FredokaOne",
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = "Rate: " .. Alyanum.new(props.Rate or 0):toString() .. "/s",
			TextColor3 = Color3.fromRGB(100, 255, 100),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 4,
		}, {
			UITextSizeConstraint = e(textsize, { Min = 12, Max = 12 }),
		}),
	})
end

return React.memo(function(props)
	return e(InventoryItem, props)
end)
