local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local ItemViewport = require(script.Parent.ItemViewport)
local textsize = require(script.Parent.textsize)
local TiersConfig = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)
local ItemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local MoneyDisplayUpdate: UnreliableRemoteEvent =
	game.ReplicatedStorage.Shared.Events:WaitForChild("MoneyDisplayUpdate")

type PlayerData = {
	Resources: { [string]: number },
	OwnedItems: { [string]: boolean },
	UnlockedItems: { [string]: boolean },
}

local OPEN_POS = UDim2.new(0.5, 0, 0.5, 0)

-- Helper component for shop item card with tooltip
local function ShopItemCard(props: {
	itemConfig: any,
	itemId: string,
	Price: number,
	buttonText: string,
	buttonColor: Color3,
})
	local itemTip = props.itemConfig.ItemTip
	local tier = TiersConfig[props.itemConfig.TierId]
	return e("Frame", {
		BackgroundColor3 = tier.ColorPrimary,
		BackgroundTransparency = 0,
		LayoutOrder = props.Price,
		AutomaticSize = Enum.AutomaticSize.XY,
		ZIndex = 2,
	}, {
		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		}),
		rounded = e(require(script.Parent.ui.rounded)),
		inside = e("Frame", {
			BackgroundTransparency = 0,
			LayoutOrder = props.Price,
			AutomaticSize = Enum.AutomaticSize.XY,
			ZIndex = 3,
			BackgroundColor3 = Color3.fromRGB(50, 50, 60),
		}, {
			rounded = e(require(script.Parent.ui.rounded)),
			UIPadding = e("UIPadding", {
				PaddingTop = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
			grid = e("UIGridLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				CellSize = UDim2.new(0.5, -4, 1, 0),
				CellPadding = UDim2.new(0, 8, 0, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirectionMaxCells = 2,
			}),
			ItemImage = e(ItemViewport, {
				ItemId = props.itemId,
				BackgroundTransparency = 1,
				ZIndex = 3,
				LayoutOrder = 1,
			}),
			InfoContainer = e("Frame", {
				Size = UDim2.new(0, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				ZIndex = 3,
				LayoutOrder = 2,
			}, {
				verticallist = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					HorizontalFlex = Enum.UIFlexAlignment.Fill,
					VerticalFlex = Enum.UIFlexAlignment.None,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				ItemName = e("TextLabel", {
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.XY,
					Font = "FredokaOne",
					LayoutOrder = 1,
					RichText = true,
					Text = (
						(props.itemConfig.DisplayName or props.itemId)
						.. "\n"
						.. [[<font thickness="2" size="10">]]
						.. TiersConfig[props.itemConfig.TierId].DisplayName
						.. [[</font>]]
					),
					TextColor3 = tier.ColorPrimary or Color3.new(1, 1, 1),
					TextWrapped = true,
					-- TextScaled = true,
					ZIndex = 3,
				}, {
					UITextSizeConstraint = e(textsize, { Min = 16, Max = 16 }),
				}),

				ItemTip = itemTip and e("TextLabel", {
					LayoutOrder = 6,
					BackgroundTransparency = 1,
					Font = "FredokaOne",
					RichText = true,
					Text = itemTip:gsub("\n", " "),
					TextColor3 = Color3.fromRGB(200, 200, 200),
					TextWrapped = true,
					-- TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					ZIndex = 3,
					AutomaticSize = Enum.AutomaticSize.Y,
				}, {
					UITextSizeConstraint = e(textsize, { Min = 10, Max = 10 }),
				}),

				RateLabel = e("TextLabel", {
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Font = "FredokaOne",
					AutomaticSize = Enum.AutomaticSize.Y,
					TextSize = 12,
					Text = "Rate: " .. Alyanum.new(props.itemConfig.Rate or 0):toString() .. "/s",
					TextColor3 = Color3.fromRGB(100, 255, 100),
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 3,
				}, {
					UITextSizeConstraint = e(textsize, { Min = 16, Max = 16 }),
				}),

				PriceLabel = e("TextLabel", {
					LayoutOrder = 4,
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Font = "FredokaOne",
					TextSize = 14,
					Text = "Price: " .. Alyanum.new(props.Price):toString(),
					TextColor3 = Color3.fromRGB(255, 215, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 3,
				}, {
					UITextSizeConstraint = e(textsize, { Min = 14, Max = 14 }),
				}),

				BuyButton = e("TextButton", {
					ZIndex = 3,
					BackgroundColor3 = props.buttonColor,
					BackgroundTransparency = 0,
					BorderSizePixel = 0,
					LayoutOrder = 5,
					Font = "FredokaOne",
					TextSize = 14,
					AutomaticSize = Enum.AutomaticSize.Y,
					Text = props.buttonText,
					TextColor3 = Color3.new(1, 1, 1),
					Active = true,
					[React.Event.Activated] = function()
						local BuyItem = game.ReplicatedStorage.Shared.Events:FindFirstChild("BuyItem") :: RemoteEvent
						if BuyItem then
							BuyItem:FireServer(props.itemId)
						end
					end,
				}, {
					rounded = e(require(script.Parent.ui.rounded)),
					UIPadding = e("UIPadding", {
						PaddingTop = UDim.new(0, 8),
						PaddingRight = UDim.new(0, 8),
						PaddingLeft = UDim.new(0, 8),
						PaddingBottom = UDim.new(0, 8),
					}),
					UITextSizeConstraint = e(textsize, { Min = 14, Max = 14 }),
				}),
			}),
		}),
	})
end

local function Shop(props: {
	PlayerData: PlayerData?,
	ShopOpen: boolean?,
	close: () -> ()?,
})
	local PlayerData: PlayerData = props.PlayerData or {}
	local currentTab, setCurrentTab = useState("Items") -- "Items" or "Premium"
	local money, setMoney = useState((PlayerData and PlayerData.Resources and PlayerData.Resources.Money) or 0)

	local FrameRef = React.useRef()
	local ScrollingFrameRef = React.useRef()
	useEffect(function()
		local conn = MoneyDisplayUpdate.OnClientEvent:Connect(function(newMoney)
			if not newMoney then
				return
			end
			setMoney(newMoney)
		end)
		return function()
			conn:Disconnect()
		end
	end)

	-- Reset scroll position when tab changes
	useEffect(function()
		local scrollingFrame = ScrollingFrameRef.current
		if scrollingFrame then
			scrollingFrame.CanvasPosition = Vector2.new(0, 0)
		end
	end, { currentTab })

	-- Helper functions for premium shop
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

	-- Build Item Shop Content
	local itemShopChildren = {
		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
		UIGridLayout = e("UIGridLayout", {
			CellSize = UDim2.new(0.5, -8, 0, 150),
			CellPadding = UDim2.new(0, 8, 0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for i, itemConfig in ipairs(ItemsConfig) do
		local itemId = itemConfig.ItemId
		local Price = itemConfig.Price or 0
		-- local isOwned = PlayerData.OwnedItems and PlayerData.OwnedItems[itemId]
		-- local isUnlocked = PlayerData.UnlockedItems and PlayerData.UnlockedItems[itemId]

		local buttonText = "BUY"
		local buttonColor = money < Price and Color3.new(1, 0.4, 0.4) or Color3.fromRGB(50, 200, 50)
		-- if isOwned then
		--     buttonText = "OWNED"
		--     buttonColor = Color3.fromRGB(100, 100, 100)
		-- elseif not isUnlocked then
		--     buttonText = "LOCKED"
		--     buttonColor = Color3.fromRGB(200, 50, 50)
		-- end

		itemShopChildren[itemId] = e(ShopItemCard, {
			itemConfig = itemConfig,
			itemId = itemId,
			Price = Price,
			buttonText = buttonText,
			buttonColor = buttonColor,
		})
	end

	-- Build Premium Shop Content
	local premiumShopChildren = {
		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
		UIListLayout = e("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),

		-- Products Section
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
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundTransparency = 1,
				Text = "🎁 Developer Products",
				Font = Enum.Font.FredokaOne,
				TextSize = 22,
				TextColor3 = Color3.fromRGB(255, 215, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
			}),
			--[[
			-- Product1 = e("TextButton", {
			-- 	Text = "",
			-- 	Size = UDim2.new(1, 0, 0, 70),
			-- 	BackgroundColor3 = Color3.fromRGB(60, 60, 70),
			-- 	AutoButtonColor = false,
			-- 	LayoutOrder = 2,
			-- 	[React.Event.Activated] = function()
			-- 		purchaseProduct(3355401894)
			-- 	end,
			-- }, {
			-- 	UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			-- 	UIPadding = e("UIPadding", {
			-- 		PaddingLeft = UDim.new(0, 15),
			-- 		PaddingRight = UDim.new(0, 15),
			-- 	}),
			-- 	Name = e("TextLabel", {
			-- 		Size = UDim2.new(0.6, 0, 1, 0),
			-- 		BackgroundTransparency = 1,
			-- 		Text = "💵 Money Pack Small",
			-- 		Font = Enum.Font.FredokaOne,
			-- 		TextSize = 18,
			-- 		TextColor3 = Color3.new(1, 1, 1),
			-- 		TextXAlignment = Enum.TextXAlignment.Left,
			-- 	}),
			-- 	Info = e("TextLabel", {
			-- 		Size = UDim2.new(0.4, 0, 1, 0),
			-- 		Position = UDim2.new(0.6, 0, 0, 0),
			-- 		BackgroundTransparency = 1,
			-- 		Text = "1,000 Money\n⭐ 25 Robux",
			-- 		Font = Enum.Font.FredokaOne,
			-- 		TextSize = 14,
			-- 		TextColor3 = Color3.fromRGB(100, 255, 100),
			-- 		TextXAlignment = Enum.TextXAlignment.Right,
			-- 	}),
			-- }),

			-- Product2 = e("TextButton", {
			-- 	Text = "",
			-- 	Size = UDim2.new(1, 0, 0, 70),
			-- 	BackgroundColor3 = Color3.fromRGB(60, 60, 70),
			-- 	AutoButtonColor = false,
			-- 	LayoutOrder = 3,
			-- 	[React.Event.Activated] = function()
			-- 		purchaseProduct(3355402539)
			-- 	end,
			-- }, {
			-- 	UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			-- 	UIPadding = e("UIPadding", {
			-- 		PaddingLeft = UDim.new(0, 15),
			-- 		PaddingRight = UDim.new(0, 15),
			-- 	}),
			-- 	Name = e("TextLabel", {
			-- 		Size = UDim2.new(0.6, 0, 1, 0),
			-- 		BackgroundTransparency = 1,
			-- 		Text = "💵 Money Pack Medium",
			-- 		Font = Enum.Font.FredokaOne,
			-- 		TextSize = 18,
			-- 		TextColor3 = Color3.new(1, 1, 1),
			-- 		TextXAlignment = Enum.TextXAlignment.Left,
			-- 	}),
			-- 	Info = e("TextLabel", {
			-- 		Size = UDim2.new(0.4, 0, 1, 0),
			-- 		Position = UDim2.new(0.6, 0, 0, 0),
			-- 		BackgroundTransparency = 1,
			-- 		Text = "5,000 Money\n⭐ 100 Robux",
			-- 		Font = Enum.Font.FredokaOne,
			-- 		TextSize = 14,
			-- 		TextColor3 = Color3.fromRGB(100, 255, 100),
			-- 		TextXAlignment = Enum.TextXAlignment.Right,
			-- 	}),
			-- }),

			-- Product3 = e("TextButton", {
			-- 	Text = "",
			-- 	Size = UDim2.new(1, 0, 0, 70),
			-- 	BackgroundColor3 = Color3.fromRGB(60, 60, 70),
			-- 	AutoButtonColor = false,
			-- 	LayoutOrder = 4,
			-- 	[React.Event.Activated] = function()
			-- 		purchaseProduct(1234567892)
			-- 	end,
			-- }, {
			-- 	UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			-- 	UIPadding = e("UIPadding", {
			-- 		PaddingLeft = UDim.new(0, 15),
			-- 		PaddingRight = UDim.new(0, 15),
			-- 	}),
			-- 	Name = e("TextLabel", {
			-- 		Size = UDim2.new(0.6, 0, 1, 0),
			-- 		BackgroundTransparency = 1,
			-- 		Text = "💵 Money Pack Large",
			-- 		Font = Enum.Font.FredokaOne,
			-- 		TextSize = 18,
			-- 		TextColor3 = Color3.new(1, 1, 1),
			-- 		TextXAlignment = Enum.TextXAlignment.Left,
			-- 	}),
			-- 	Info = e("TextLabel", {
			-- 		Size = UDim2.new(0.4, 0, 1, 0),
			-- 		Position = UDim2.new(0.6, 0, 0, 0),
			-- 		BackgroundTransparency = 1,
			-- 		Text = "15,000 Money\n⭐ 250 Robux",
			-- 		Font = Enum.Font.FredokaOne,
			-- 		TextSize = 14,
			-- 		TextColor3 = Color3.fromRGB(100, 255, 100),
			-- 		TextXAlignment = Enum.TextXAlignment.Right,
			-- 	}),
			-- }),
]]
			Product4 = e("TextButton", {
				Text = "",
				Size = UDim2.new(1, 0, 0, 70),
				BackgroundColor3 = Color3.fromRGB(80, 60, 120),
				AutoButtonColor = false,
				LayoutOrder = 5,
				[React.Event.Activated] = function()
					purchaseProduct(3450086552)
				end,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
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
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundTransparency = 1,
				Text = "🎫 Game Passes",
				Font = Enum.Font.FredokaOne,
				TextSize = 22,
				TextColor3 = Color3.fromRGB(100, 200, 255),
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
			}),

			GamePass1 = e("TextButton", {
				Text = "",
				Size = UDim2.new(1, 0, 0, 70),
				BackgroundColor3 = Color3.fromRGB(120, 80, 200),
				AutoButtonColor = false,
				LayoutOrder = 2,
				[React.Event.Activated] = function()
					purchaseGamePass(1574431723)
				end,
			}, {
				UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
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

			-- GamePass2 = e("TextButton", {
			--     Text = "",
			--     Size = UDim2.new(1, 0, 0, 70),
			--     BackgroundColor3 = Color3.fromRGB(80, 160, 200),
			--     AutoButtonColor = false,
			--     LayoutOrder = 3,
			--     [React.Event.Activated] = function()
			--         purchaseGamePass(12345679)
			--     end,
			-- }, {
			--     UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			--     UIPadding = e("UIPadding", {
			--         PaddingLeft = UDim.new(0, 15),
			--         PaddingRight = UDim.new(0, 15),
			--     }),
			--     Name = e("TextLabel", {
			--         Size = UDim2.new(0.6, 0, 1, 0),
			--         BackgroundTransparency = 1,
			--         Text = "🤖 Auto Collector",
			--         Font = Enum.Font.FredokaOne,
			--         TextSize = 18,
			--         TextColor3 = Color3.fromRGB(100, 255, 255),
			--         TextXAlignment = Enum.TextXAlignment.Left,
			--     }),
			--     Info = e("TextLabel", {
			--         Size = UDim2.new(0.4, 0, 1, 0),
			--         Position = UDim2.new(0.6, 0, 0, 0),
			--         BackgroundTransparency = 1,
			--         Text = "Auto collect!\n⭐ Price TBD",
			--         Font = Enum.Font.FredokaOne,
			--         TextSize = 14,
			--         TextColor3 = Color3.fromRGB(100, 255, 255),
			--         TextXAlignment = Enum.TextXAlignment.Right,
			--     }),
			-- }),
		}),
	}

	return e("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = OPEN_POS, --CLOSED_POS,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(0.2, 0.1, 0.3),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = false,
		Visible = props.ShopOpen, -- visible,
		ref = FrameRef,
		ClipsDescendants = false,
		ZIndex = 1,
		Image = "rbxassetid://136242854116857",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(30, 30, 90, 90),
	}, {
		UIGradient = e("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(100, 50, 150), Color3.fromRGB(150, 100, 200)),
		}),
		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 30),
			PaddingLeft = UDim.new(0, 30),
			PaddingBottom = UDim.new(0, 16),
		}),

		-- Title
		Title = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 40),
			Position = UDim2.new(0.5, 0, 0, -10),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Font = "FredokaOne",
			TextSize = 32,
			Text = currentTab == "Items" and "💰ITEM SHOP" or "💲PREMIUM SHOP",
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0,
			ZIndex = 2,
		}),

		-- Tab Buttons
		TabButtons = e("Frame", {
			Size = UDim2.new(1, 0, 0, 40),
			Position = UDim2.new(0, 0, 0, 35),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, {
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 10),
			}),

			ItemsTab = e("TextButton", {
				Size = UDim2.new(0, 150, 1, 0),
				BackgroundColor3 = currentTab == "Items" and Color3.fromRGB(100, 200, 100)
					or Color3.fromRGB(60, 60, 70),
				BorderSizePixel = 0,
				Font = "FredokaOne",
				TextSize = 18,
				Text = "🛒 Items",
				TextColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					setCurrentTab("Items")
				end,
			}, {
				rounded = e(require(script.Parent.ui.rounded)),
			}),

			PremiumTab = e("TextButton", {
				Size = UDim2.new(0, 150, 1, 0),
				BackgroundColor3 = currentTab == "Premium" and Color3.fromRGB(200, 100, 200)
					or Color3.fromRGB(60, 60, 70),
				BorderSizePixel = 0,
				Font = "FredokaOne",
				TextSize = 18,
				Text = "⭐ Premium",
				TextColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					setCurrentTab("Premium")
				end,
			}, {
				rounded = e(require(script.Parent.ui.rounded)),
			}),
		}),

		-- Content ScrollingFrame
		ScrollingFrame = e("ScrollingFrame", {
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Size = UDim2.new(1, 0, 1, -90),
			Position = UDim2.new(0, 0, 0, 90),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Active = false,
			ZIndex = 2,
			ClipsDescendants = true,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ref = ScrollingFrameRef,
		}, currentTab == "Items" and itemShopChildren or premiumShopChildren),

		UISizeConstraint = e("UISizeConstraint", {
			MaxSize = Vector2.new(720, 480),
		}),

		CloseButton = e("TextButton", {
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
	})
end

return Shop
