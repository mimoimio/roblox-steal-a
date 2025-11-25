local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local ItemViewport = require(script.Parent.ItemViewport)
local TiersConfig = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)

local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type PlayerData = sharedtypes.PlayerData

-- Helper component for shop item card with tooltip
local function ShopItemCard(props: {
	itemConfig: any,
	itemId: string,
	Price: number,
	buttonText: string,
	buttonColor: Color3,
	slotNum: string?,
	isReward: boolean?,
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
					-- Size = UDim2.new(1,0, 0, 30),
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.XY,
					Font = "FredokaOne",
					LayoutOrder = 1,
					TextSize = 16,
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
				}),

				ItemTip = itemTip and e("TextLabel", {
					LayoutOrder = 6,
					BackgroundTransparency = 1,
					Font = "FredokaOne",
					TextSize = 10,
					RichText = true,
					Text = itemTip:gsub("\n", " "),
					TextColor3 = Color3.fromRGB(200, 200, 200),
					TextWrapped = true,
					-- TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					ZIndex = 3,
					AutomaticSize = Enum.AutomaticSize.Y,
				}),

				RateLabel = e("TextLabel", {
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Font = "FredokaOne",
					AutomaticSize = Enum.AutomaticSize.Y,
					TextSize = 12,
					Text = "Rate: " .. (props.itemConfig.Rate or 0) .. "/s",
					TextColor3 = Color3.fromRGB(100, 255, 100),
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 3,
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
						if props.isReward and props.slotNum then
							local ProcessReward =
								game.ReplicatedStorage.Shared.Events:FindFirstChild("ProcessReward") :: RemoteEvent
							if ProcessReward then
								ProcessReward:FireServer(props.slotNum, props.itemId)
							end
						else
							local BuyItem =
								game.ReplicatedStorage.Shared.Events:FindFirstChild("BuyItem") :: RemoteEvent
							if BuyItem then
								BuyItem:FireServer(props.itemId)
							end
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
				}),
			}),
		}),
	})
end

local function Shop(props: {
	PlayerData: PlayerData?,
	RewardOpen: boolean?,
	close: () -> ()?,
	money: number?,
	rate: number?,
	multipliers: any?,
	slotNum: string?,
})
	local PlayerData: PlayerData = props.PlayerData or {}
	local Money = props.money or (PlayerData and PlayerData.Resources and PlayerData.Resources.Money) or 0
	local Phase: "opening" | "open" | "closing" | "closed", setPhase = useState("closed")
	local currentTab, setCurrentTab = useState("Items") -- "Items" or "Premium"

	-- Get all item configs
	local ItemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
	local ItemConfigsById = {}
	for _, cfg in ipairs(ItemsConfig) do
		ItemConfigsById[cfg.ItemId] = cfg
	end
	local FrameRef = React.useRef()
	local ScrollingFrameRef = React.useRef()

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

	-- Check if we have reward items for this slot
	local rewardItemIds = props.slotNum and PlayerData.Rewards and PlayerData.Rewards[props.slotNum]
	local itemsToDisplay = {}

	if rewardItemIds and #rewardItemIds == 3 then
		-- Display only the 3 reward items
		for _, itemId in ipairs(rewardItemIds) do
			local itemConfig = ItemConfigsById[itemId]
			if itemConfig then
				table.insert(itemsToDisplay, itemConfig)
			end
		end
	else
		-- Display all items (shop mode)
		itemsToDisplay = ItemsConfig
	end

	for i, itemConfig in ipairs(itemsToDisplay) do
		local itemId = itemConfig.ItemId
		local Price = itemConfig.Price or 0
		local isReward = rewardItemIds ~= nil

		local buttonText = isReward and "SELECT" or "BUY"
		local buttonColor = isReward and Color3.fromRGB(100, 150, 255)
			or (Money < Price and Color3.new(1, 0.4, 0.4) or Color3.fromRGB(50, 200, 50))

		itemShopChildren[itemId] = e(ShopItemCard, {
			itemConfig = itemConfig,
			itemId = itemId,
			Price = Price,
			buttonText = buttonText,
			buttonColor = buttonColor,
			slotNum = props.slotNum,
			isReward = isReward,
		})
	end

	return e("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(0.2, 0.1, 0.3),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = false,
		Visible = props.RewardOpen, -- visible,
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
			Text = "PICK A REWARD",
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0,
			ZIndex = 2,
		}),

		-- Content ScrollingFrame
		ScrollingFrame = e("ScrollingFrame", {
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Size = UDim2.new(1, 0, 1, -40),
			Position = UDim2.new(0, 0, 0, 40),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Active = false,
			ZIndex = 2,
			ClipsDescendants = true,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ref = ScrollingFrameRef,
		}, itemShopChildren),

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
