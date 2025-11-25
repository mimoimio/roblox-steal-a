local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local TS = game:GetService("TweenService")
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)

type PlayerData = {
	Resources: { [string]: number },
	OwnedItems: { [string]: boolean },
	UnlockedItems: { [string]: boolean },
}

local OPEN_POS = UDim2.new(0.5, 0, 0.5, 0)
local OPEN_ROT = 0
local CLOSED_POS = UDim2.new(1.5, 0, 0.5, 0)
local CLOSED_ROT = 0

local function ItemShop(props: {
	PlayerData: PlayerData?,
	ShopOpen: boolean?,
	close: () -> ()?,
})
	local PlayerData: PlayerData = props.PlayerData or {}
	local Phase: "opening" | "open" | "closing" | "closed", setPhase = React.useState("closed")
	local visible, setVisible = React.useState(Phase ~= "closed")

	-- Get all item configs
	local ItemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)

	local children = {
		UIGridLayout = e("UIGridLayout", {
			CellSize = UDim2.new(0, 150, 0, 200),
			CellPadding = UDim2.new(0, 8, 0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	-- Iterate through all items in config
	for i, itemConfig in ipairs(ItemsConfig) do
		local itemId = itemConfig.ItemId
		local Price = itemConfig.Price or 0
		children[itemId] = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(50, 50, 60),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			LayoutOrder = Price,
		}, {
			rounded = e(require(script.Parent.ui.rounded)),
			UIPadding = e("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			}),
			verticallist = e(require(script.Parent.ui.verticallist)),

			-- Item Icon/Image
			ItemImage = e("ImageLabel", {
				Size = UDim2.new(1, 0, 0, 80),
				BackgroundTransparency = 1,
				Image = itemConfig.Image or "rbxassetid://0",
				ScaleType = Enum.ScaleType.Fit,
			}),

			-- Item Name
			ItemName = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundTransparency = 1,
				Font = "FredokaOne",
				TextSize = 16,
				Text = itemConfig.DisplayName or itemId,
				TextColor3 = Color3.new(1, 1, 1),
				TextWrapped = true,
				TextScaled = true,
			}),

			-- Base Rate Info
			RateLabel = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Font = "FredokaOne",
				TextSize = 12,
				Text = "Rate: " .. (itemConfig.Rate or 0) .. "/s",
				TextColor3 = Color3.fromRGB(100, 255, 100),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			-- Price Label
			PriceLabel = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Font = "FredokaOne",
				TextSize = 14,
				Text = "Price: " .. Alyanum.new(Price):toString(),
				TextColor3 = Color3.fromRGB(255, 215, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			-- Buy Button or Status
			BuyButton = e("TextButton", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = Color3.fromRGB(50, 200, 50),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Font = "FredokaOne",
				TextSize = 14,
				Text = "BUY",
				TextColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					local BuyItem = game.ReplicatedStorage.Shared.Events:FindFirstChild("BuyItem")
					if BuyItem then
						BuyItem:FireServer(itemId)
					end
				end,
			}, {
				rounded = e(require(script.Parent.ui.rounded)),
			}),
		})
	end

	local animDur = 0.4
	local FrameRef = React.useRef()
	local tweenRef = React.useRef(nil)

	React.useEffect(function()
		local frame = FrameRef.current
		if not frame then
			return
		end

		-- Cancel previous tween if any
		if tweenRef.current then
			tweenRef.current:Cancel()
			tweenRef.current = nil
		end

		if props.ShopOpen then
			setPhase("opening")
			setVisible(true) -- show immediately
			local tween = TS:Create(frame, TweenInfo.new(animDur), { Position = OPEN_POS, Rotation = OPEN_ROT })
			tweenRef.current = tween
			tween.Completed:Connect(function(playbackState)
				if playbackState == Enum.PlaybackState.Completed then
					setPhase("open")
				end
			end)
			tween:Play()
		else
			setPhase("closing")
			local tween = TS:Create(frame, TweenInfo.new(animDur), { Position = CLOSED_POS, Rotation = CLOSED_ROT })
			tweenRef.current = tween
			tween.Completed:Connect(function(playbackState)
				if playbackState == Enum.PlaybackState.Completed then
					setPhase("closed")
					setVisible(false) -- hide after close finishes
				end
			end)
			tween:Play()
		end
	end, { props.ShopOpen })

	return e("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = CLOSED_POS,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(0.2, 0.1, 0.3),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = false,
		Visible = visible,
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
			PaddingTop = UDim.new(0, 30),
			PaddingRight = UDim.new(0, 30),
			PaddingLeft = UDim.new(0, 30),
			PaddingBottom = UDim.new(0, 30),
		}),

		-- Title
		Title = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 40),
			Position = UDim2.new(0.5, 0, 0, -10),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Font = "FredokaOne",
			TextSize = 32,
			Text = "ITEM SHOP",
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0,
			ZIndex = 2,
		}),

		ScrollingFrame = e("ScrollingFrame", {
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Size = UDim2.new(1, 0, 1, -50),
			Position = UDim2.new(0, 0, 0, 50),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Active = false,
			ZIndex = 2,
			ClipsDescendants = true,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, children),

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

return ItemShop
