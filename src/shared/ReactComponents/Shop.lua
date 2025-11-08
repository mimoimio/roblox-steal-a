local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement

local function Shop(props)
	local isOpen, setIsOpen = React.useState(props.IsOpen or false)

	-- Update when props change
	React.useEffect(function()
		setIsOpen(props.IsOpen or false)
	end, { props.IsOpen })

	local function purchaseProduct(productId)
		local PurchaseProduct = game.ReplicatedStorage.Shared.Events:FindFirstChild("PurchaseProduct")
		if PurchaseProduct then
			PurchaseProduct:FireServer(productId)
		else
			warn("[Shop] PurchaseProduct event not found")
		end
	end

	local function purchaseGamePass(gamePassId)
		local PurchaseGamePass = game.ReplicatedStorage.Shared.Events:FindFirstChild("PurchaseGamePass")
		if PurchaseGamePass then
			PurchaseGamePass:FireServer(gamePassId)
		else
			warn("[Shop] PurchaseGamePass event not found")
		end
	end

	if not isOpen then
		return nil
	end

	return e("Frame", {
		Name = "ShopPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(40, 40, 45),
		BorderSizePixel = 0,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),

		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 20),
			PaddingBottom = UDim.new(0, 20),
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
		}),

		-- Header
		Header = e("Frame", {
			Name = "Header",
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundTransparency = 1,
		}, {
			Title = e("TextLabel", {
				Size = UDim2.new(1, -50, 1, 0),
				BackgroundTransparency = 1,
				Text = "💰 Shop",
				Font = Enum.Font.FredokaOne,
				TextSize = 28,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			CloseButton = e("TextButton", {
				Name = "CloseButton",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.new(0, 40, 0, 40),
				BackgroundColor3 = Color3.fromRGB(220, 50, 50),
				Text = "✕",
				Font = Enum.Font.FredokaOne,
				TextSize = 24,
				TextColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = props.OnClose,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
		}),

		-- Content with ScrollingFrame
		Content = e("ScrollingFrame", {
			Name = "Content",
			Position = UDim2.new(0, 0, 0, 50),
			Size = UDim2.new(1, 0, 1, -50),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, {
			UIListLayout = e("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 15),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),

			-- Developer Products Section
			ProductsSection = e("Frame", {
				Name = "ProductsSection",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				UIListLayout = e("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 10),
				}),

				SectionTitle = e("TextLabel", {
					Name = "SectionTitle",
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					Text = "🎁 Products",
					Font = Enum.Font.FredokaOne,
					TextSize = 22,
					TextColor3 = Color3.fromRGB(255, 215, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 1,
				}),

				-- Money Pack Small
				Product1 = e("TextButton", {
					Name = "Product_3355401894",
					Size = UDim2.new(1, 0, 0, 70),
					BackgroundColor3 = Color3.fromRGB(60, 60, 70),
					AutoButtonColor = false,
					LayoutOrder = 2,
					[React.Event.Activated] = function()
						purchaseProduct(3355401894)
					end,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),
					UIPadding = e("UIPadding", {
						PaddingLeft = UDim.new(0, 15),
						PaddingRight = UDim.new(0, 15),
					}),

					Name = e("TextLabel", {
						Size = UDim2.new(0.6, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "💵 Money Pack Small",
						Font = Enum.Font.FredokaOne,
						TextSize = 18,
						TextColor3 = Color3.new(1, 1, 1),
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					Info = e("TextLabel", {
						Size = UDim2.new(0.4, 0, 1, 0),
						Position = UDim2.new(0.6, 0, 0, 0),
						BackgroundTransparency = 1,
						Text = "1,000 Money\n⭐ 25 Robux",
						Font = Enum.Font.FredokaOne,
						TextSize = 14,
						TextColor3 = Color3.fromRGB(100, 255, 100),
						TextXAlignment = Enum.TextXAlignment.Right,
					}),
				}),

				-- Money Pack Medium
				Product2 = e("TextButton", {
					Name = "Product_3355402539",
					Size = UDim2.new(1, 0, 0, 70),
					BackgroundColor3 = Color3.fromRGB(60, 60, 70),
					AutoButtonColor = false,
					LayoutOrder = 3,
					[React.Event.Activated] = function()
						purchaseProduct(3355402539)
					end,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),
					UIPadding = e("UIPadding", {
						PaddingLeft = UDim.new(0, 15),
						PaddingRight = UDim.new(0, 15),
					}),

					Name = e("TextLabel", {
						Size = UDim2.new(0.6, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "💵 Money Pack Medium",
						Font = Enum.Font.FredokaOne,
						TextSize = 18,
						TextColor3 = Color3.new(1, 1, 1),
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					Info = e("TextLabel", {
						Size = UDim2.new(0.4, 0, 1, 0),
						Position = UDim2.new(0.6, 0, 0, 0),
						BackgroundTransparency = 1,
						Text = "5,000 Money\n⭐ 100 Robux",
						Font = Enum.Font.FredokaOne,
						TextSize = 14,
						TextColor3 = Color3.fromRGB(100, 255, 100),
						TextXAlignment = Enum.TextXAlignment.Right,
					}),
				}),

				-- Money Pack Large
				Product3 = e("TextButton", {
					Name = "Product_1234567892",
					Size = UDim2.new(1, 0, 0, 70),
					BackgroundColor3 = Color3.fromRGB(60, 60, 70),
					AutoButtonColor = false,
					LayoutOrder = 4,
					[React.Event.Activated] = function()
						purchaseProduct(1234567892)
					end,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),
					UIPadding = e("UIPadding", {
						PaddingLeft = UDim.new(0, 15),
						PaddingRight = UDim.new(0, 15),
					}),

					Name = e("TextLabel", {
						Size = UDim2.new(0.6, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "💵 Money Pack Large",
						Font = Enum.Font.FredokaOne,
						TextSize = 18,
						TextColor3 = Color3.new(1, 1, 1),
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					Info = e("TextLabel", {
						Size = UDim2.new(0.4, 0, 1, 0),
						Position = UDim2.new(0.6, 0, 0, 0),
						BackgroundTransparency = 1,
						Text = "15,000 Money\n⭐ 250 Robux",
						Font = Enum.Font.FredokaOne,
						TextSize = 14,
						TextColor3 = Color3.fromRGB(100, 255, 100),
						TextXAlignment = Enum.TextXAlignment.Right,
					}),
				}),

				-- 2x Money Boost
				Product4 = e("TextButton", {
					Name = "Product_1234567894",
					Size = UDim2.new(1, 0, 0, 70),
					BackgroundColor3 = Color3.fromRGB(80, 60, 120),
					AutoButtonColor = false,
					LayoutOrder = 5,
					[React.Event.Activated] = function()
						purchaseProduct(3450086552)
					end,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),
					UIPadding = e("UIPadding", {
						PaddingLeft = UDim.new(0, 15),
						PaddingRight = UDim.new(0, 15),
					}),

					Name = e("TextLabel", {
						Size = UDim2.new(0.6, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "⚡ 2x Money Boost",
						Font = Enum.Font.FredokaOne,
						TextSize = 18,
						TextColor3 = Color3.fromRGB(255, 215, 0),
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					Info = e("TextLabel", {
						Size = UDim2.new(0.4, 0, 1, 0),
						Position = UDim2.new(0.6, 0, 0, 0),
						BackgroundTransparency = 1,
						Text = "15 Minutes\n⭐ 75 Robux",
						Font = Enum.Font.FredokaOne,
						TextSize = 14,
						TextColor3 = Color3.fromRGB(255, 215, 0),
						TextXAlignment = Enum.TextXAlignment.Right,
					}),
				}),
			}),

			-- GamePasses Section
			GamePassesSection = e("Frame", {
				Name = "GamePassesSection",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				UIListLayout = e("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 10),
				}),

				SectionTitle = e("TextLabel", {
					Name = "SectionTitle",
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					Text = "🎫 Game Passes",
					Font = Enum.Font.FredokaOne,
					TextSize = 22,
					TextColor3 = Color3.fromRGB(100, 200, 255),
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 1,
				}),

				-- 2x Money Forever
				GamePass1 = e("TextButton", {
					Name = "GamePass_12345678",
					Size = UDim2.new(1, 0, 0, 70),
					BackgroundColor3 = Color3.fromRGB(120, 80, 200),
					AutoButtonColor = false,
					LayoutOrder = 2,
					[React.Event.Activated] = function()
						purchaseGamePass(1574431723)
					end,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),
					UIPadding = e("UIPadding", {
						PaddingLeft = UDim.new(0, 15),
						PaddingRight = UDim.new(0, 15),
					}),

					Name = e("TextLabel", {
						Size = UDim2.new(0.6, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "⭐ 2x Money Forever",
						Font = Enum.Font.FredokaOne,
						TextSize = 18,
						TextColor3 = Color3.fromRGB(255, 215, 0),
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					Info = e("TextLabel", {
						Size = UDim2.new(0.4, 0, 1, 0),
						Position = UDim2.new(0.6, 0, 0, 0),
						BackgroundTransparency = 1,
						Text = "Permanent!\n⭐ Price TBD",
						Font = Enum.Font.FredokaOne,
						TextSize = 14,
						TextColor3 = Color3.fromRGB(255, 215, 0),
						TextXAlignment = Enum.TextXAlignment.Right,
					}),
				}),

				-- Auto Collector
				GamePass2 = e("TextButton", {
					Name = "GamePass_12345679",
					Size = UDim2.new(1, 0, 0, 70),
					BackgroundColor3 = Color3.fromRGB(80, 160, 200),
					AutoButtonColor = false,
					LayoutOrder = 3,
					[React.Event.Activated] = function()
						purchaseGamePass(12345679)
					end,
				}, {
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),
					UIPadding = e("UIPadding", {
						PaddingLeft = UDim.new(0, 15),
						PaddingRight = UDim.new(0, 15),
					}),

					Name = e("TextLabel", {
						Size = UDim2.new(0.6, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "🤖 Auto Collector",
						Font = Enum.Font.FredokaOne,
						TextSize = 18,
						TextColor3 = Color3.fromRGB(100, 255, 255),
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					Info = e("TextLabel", {
						Size = UDim2.new(0.4, 0, 1, 0),
						Position = UDim2.new(0.6, 0, 0, 0),
						BackgroundTransparency = 1,
						Text = "Auto collect!\n⭐ Price TBD",
						Font = Enum.Font.FredokaOne,
						TextSize = 14,
						TextColor3 = Color3.fromRGB(100, 255, 255),
						TextXAlignment = Enum.TextXAlignment.Right,
					}),
				}),
			}),
		}),
		UISizeConstraint = e("UISizeConstraint", {
			MaxSize = Vector2.new(720, 480),
		}),
	})
end

return Shop
