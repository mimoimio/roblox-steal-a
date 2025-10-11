type Item = {
	UID: string, --
	ItemId: string,
	DisplayName: string,
	Rate: number,
}
local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type ItemConfig = sharedtypes.ItemConfig
local TS = game:GetService("TweenService")
local PICell = require(script.Parent.PICell)
local rounded = require(script.Parent.ui.rounded)

local OPEN_POS = UDim2.new(0.5, 0, 0.5, 0)
local OPEN_ROT = 0
local CLOSED_POS = UDim2.new(-0.5, 0, 0.5, 0)
local CLOSED_ROT = math.pi * 0

local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef
local useState = React.useState

type Slot = "Slot1" | "Slot2" | "Slot3" | "Slot4" | "Slot5" | "Slot6"
local itemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local tiersConfig = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)
local function MainShop(props: {})
	local Phase: "opening" | "open" | "closing" | "closed", setPhase = React.useState("closed")
	local visible, setVisible = React.useState(Phase ~= "closed")

	local SFRef = React.useRef()
	useEffect(function()
		local sf = SFRef.current
		if sf and sf:IsA("ScrollingFrame") then
			local as = sf.ScrollWrapper.AbsoluteSize
			sf.CanvasSize = UDim2.new(0, as.X, 0, as.Y)
		end
	end, { props.Items })

	local children = {
		verticallist = e("UIGridLayout", {
			CellSize = UDim2.new(1, 0, 0, 100),
			CellPadding = UDim2.new(0, 8, 0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	}

	local childNum = 0
	for i, itemConfig: ItemConfig in itemsConfig or {} do
		childNum += 1
		children[itemConfig.ItemId] = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = itemConfig.Rate,
			ZIndex = 2,
		}, {
			TextLabel = e("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 0.9,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				TextColor3 = tiersConfig[itemConfig.TierId].ColorPrimary,
				Font = "FredokaOne",
				TextSize = 14,
				TextWrapped = true,
				Text = itemConfig.DisplayName .. "\n" .. itemConfig.Rate .. "/s",
				TextStrokeTransparency = 0,
				RichText = true,
				ClipsDescendants = true,
				ZIndex = 4,
			}, {
				Button = e("TextButton", {
					AutomaticSize = Enum.AutomaticSize.XY,
					Position = UDim2.new(1, 0, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundTransparency = 0,
					BackgroundColor3 = Color3.new(0.1, 0.8, 0.2),
					BorderSizePixel = 0,
					TextColor3 = tiersConfig[itemConfig.TierId].ColorPrimary,
					Font = "FredokaOne",
					TextSize = 14,
					TextWrapped = true,
					Text = "BUY",
					TextStrokeTransparency = 0,
					RichText = true,
					ClipsDescendants = true,
					ZIndex = 4,
				}, e(require(script.Parent.ui.padding))),
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
		if props.MainShopOpen then
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
	end, { props.MainShopOpen })
	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = CLOSED_POS,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(0.2, 0.1, 0),
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		Active = true,
		Visible = visible,
		ref = FrameRef,
		ClipsDescendants = false,
		ZIndex = 1,
	}, {
		MainFrame = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			ClipsDescendants = true,
		}, {
			ScrollingFrame = e("ScrollingFrame", {
				ScrollingDirection = Enum.ScrollingDirection.Y,
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				ref = SFRef,
				ClipsDescendants = true,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
			}, {
				ScrollWrapper = e("Frame", {
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
				}, children),
			}),
			OpsFrame = e("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				ClipsDescendants = true,
			}, {
				pad = e(require(script.Parent.ui.padding)),
				TextButton = e("TextButton", {
					Text = "SELL",
					LayoutOrder = 2,
					TextSize = 20,
					Font = Enum.Font.FredokaOne,
					BackgroundTransparency = 0,
					BackgroundColor3 = Color3.new(1, 0.4, 0.4),
					AutomaticSize = Enum.AutomaticSize.XY,
					-- [React.Event.Activated] = function()
					-- 	props.sell(selectedItems)
					-- 	props.close()
					-- end,
				}, e(require(script.Parent.ui.padding))),

				UIListLayout = e("UIListLayout", {
					-- CellSize = UDim2.new(0.5, 0, 1, 0),
					Padding = UDim.new(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder,
					FillDirection = Enum.FillDirection.Vertical,
					-- HorizontalFlex = "Fill",
					-- FillDirectionMaxCells = 1,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
				}),
			}),
			UIGridLayout = e("UIGridLayout", {
				CellSize = UDim2.new(0.5, 0, 1, 0),
				CellPadding = UDim2.new(0, 8, 0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
				FillDirectionMaxCells = 1,
				-- HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
		}),
		UISizeConstraint = e("UISizeConstraint", {
			MaxSize = Vector2.new(720, 480),
		}),
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
			ZIndex = 2,
			[React.Event.Activated] = props.close,
			Position = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			Rounded = e(require(script.Parent.ui.rounded)),
		}),
		TextLabel = e("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0.5, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			Font = "FredokaOne",
			TextSize = 20,
			Text = "Item Shop",
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeColor3 = Color3.new(0, 0, 0),
			TextStrokeTransparency = 0,
		}),
	})
end

return MainShop
