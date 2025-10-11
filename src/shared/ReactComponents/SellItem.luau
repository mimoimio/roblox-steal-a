type Item = {
	UID: string, --
	ItemId: string,
	DisplayName: string,
	Rate: number,
}
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

local function SellItem(props: {
	Items: { Item },
	SellItemOpen: boolean,
	clicked: (() -> nil)?,
	SellSlot: Slot,
	close: () -> nil,
})
	local Phase: "opening" | "open" | "closing" | "closed", setPhase = React.useState("closed")
	local visible, setVisible = React.useState(Phase ~= "closed")
	local selectedItems, setSelecteditems = useState({} :: { [string]: boolean? })

	local children = {
		verticallist = e("UIGridLayout", {
			CellSize = UDim2.new(0, 100, 0, 100),
			CellPadding = UDim2.new(0, 8, 0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	}

	local SFRef = React.useRef()
	useEffect(function()
		local sf = SFRef.current
		if sf and sf:IsA("ScrollingFrame") then
			local as = sf.ScrollWrapper.AbsoluteSize
			sf.CanvasSize = UDim2.new(0, as.X, 0, as.Y)
		end
	end, { props.Items })
	local childNum = 0
	for i, item in props.Items or {} do
		childNum += 1
		children[item.UID] = e(PICell, {
			key = item.UID,
			UID = item.UID,
			Item = item,
			LayoutOrder = item.Rate,
			clicked = function(button: TextButton)
				if not button or not button:IsA("TextButton") then
					return
				end
				local UID = button:GetAttribute("UID")
				if not UID then
					return
				end
				setSelecteditems(function(prev)
					local newSelectedItems = table.clone(prev)
					if newSelectedItems[UID] then
						newSelectedItems[UID] = nil
					else
						newSelectedItems[UID] = true
					end
					return newSelectedItems
				end)
			end,
			Placed = (function()
				return props.PlacedItemUids[item.UID]
			end)(),
			Selected = selectedItems[item.UID],
		}, {
			rounded = e(rounded),
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
		if props.SellItemOpen then
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
	end, { props.SellItemOpen })
	return e("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = CLOSED_POS,
		AnchorPoint = Vector2.new(0.5, 0.5),
		-- BackgroundColor3 = Color3.new(0.2, 0.1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = true,
		Visible = visible,
		ref = FrameRef,
		ClipsDescendants = false,
		ZIndex = 1,
		Image = "rbxassetid://136242854116857",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(30, 30, 90, 90),
	}, {
		UIGradient = e("UIGradient", {
			Color = ColorSequence.new(Color3.new(0.352941, 0.133333, 0.203921), Color3.new(0.7, 0.5, 0.8)),
			Rotation = 90,
		}),
		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 30),
			PaddingRight = UDim.new(0, 30),
			PaddingLeft = UDim.new(0, 30),
			PaddingBottom = UDim.new(0, 30),
		}),
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
					[React.Event.Activated] = function()
						props.sell(selectedItems)
						props.close()
					end,
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
			ZIndex = 10,
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
			Text = "SELL ITEM: " .. (props.SellSlot or ""),
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeColor3 = Color3.new(0, 0, 0),
			TextStrokeTransparency = 0,
		}),
	})
end

return SellItem

--[[

	Selling an item: Item.sell( {ItemId} ): boolean
	
	gui:
		SellItemFrame {
			submitSell: (selectedItems:{string})->
		}
			PICell:{
				Selected: boolean
			}
			Confirm: {}

]]
