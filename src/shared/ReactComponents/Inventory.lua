local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local TS = game:GetService("TweenService")
type PlayerData = {
	Resources: { [string]: number },
	PlayerSettings: { MusicVolume: number },
	Progress: { EXP: number, LVL: number },
	Items: { { Item } },
	ItemSlots: { -- contains UID of items from PlayerData.Items
		Slot1: string?,
		Slot2: string?,
		Slot3: string?,
		Slot4: string?,
		Slot5: string?,
		Slot6: string?,
	},
}
type Item = {
	UID: string, --
	ItemId: string,
	DisplayName: string,
	Rate: number,
}

local OPEN_POS = UDim2.new(0.5, 0, 0.5, 0)
local OPEN_ROT = 0
local CLOSED_POS = UDim2.new(-0.5, 0, 0.5, 0)
local CLOSED_ROT = math.pi * 0

local function Inventory(props: {
	PlayerData: PlayerData?,
	isMountedRef: { current: boolean }?,
})
	local PlayerData: PlayerData = props.PlayerData or {}
	local Items: { Item } = PlayerData.Items or {}
	local Phase: "opening" | "open" | "closing" | "closed", setPhase = React.useState("closed")
	local visible, setVisible = React.useState(Phase ~= "closed")

	local children = {
		verticallist = e("UIGridLayout", {
			CellSize = UDim2.new(0, 100, 0, 100),
			CellPadding = UDim2.new(0, 8, 0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	local SFRef = React.useRef()
	local childNum = 0

	-- Abstracted per-item UI component with mount tween (see InventoryItem.luau)
	local InventoryItem = require(script.Parent.InventoryItem)
	for i, item in Items do
		if not item.UID then
			warn("✨✨✨", item.UID or item)
			continue
		end
		childNum += 1
		children["item" .. item.UID] = e(InventoryItem, {
			key = item.UID,
			UID = item.UID,
			Item = item,
			LayoutOrder = item.Rate,
			isMountedRef = props.isMountedRef,
			InventoryOpen = props.InventoryOpen,
		}, {
			rounded = e(require(script.Parent.ui.rounded)),
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
		if props.InventoryOpen then
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
	end, { props.InventoryOpen })

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = CLOSED_POS,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(0, 0.2, 0.2),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Active = false,
		Visible = visible,
		ref = FrameRef,
		ClipsDescendants = false,
		ZIndex = 1,
	}, {
		ScrollingFrame = e("ScrollingFrame", {
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			ref = SFRef,
			Active = false,
			ZIndex = 2,
			ClipsDescendants = true,
			AutomaticCanvasSize = Enum.AutomaticSize.XY,
		}, children),
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
	})
end

return Inventory
