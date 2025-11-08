local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local RunService = game:GetService("RunService")
local TS = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local useToast = require(game.ReplicatedStorage.Shared.ReactComponents.Toasts).useToast

local itemConfigs = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local variationConfigs = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
local tierConfigs = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)
local FormatItemLabelText = require(game.ReplicatedStorage.Shared.Utils.Format).FormatItemLabelText

type Item = {
	UID: string, --
	ItemId: string,
	DisplayName: string,
	Rate: number,
}
local DEFAULT_TWEEN = 0.25
local MOUNTED_SIZE = UDim2.new(1, 0, 1, 0)
local Size = MOUNTED_SIZE

local function PICell(props: {
	UID: string,
	Item: Item,
	LayoutOrder: number,
	clicked: () -> nil,
	Selected: boolean,
})
	local frameRef = React.useRef(nil)
	local tooltipRef = React.useRef(nil)
	local resconnRef = React.useRef(nil)
	local text = (props.Item.Entered and "" or "*") .. FormatItemLabelText(props.Item)
	local mouseEnter, setMouseEnter = React.useState(false)

	React.useEffect(function()
		-- Tooltip logic
		local tip = itemConfigs[props.Item.ItemId] and itemConfigs[props.Item.ItemId].ItemTip
		if not tip then
			return
		end
		if tooltipRef.current then
			tooltipRef.current:Destroy()
		end

		if mouseEnter then
			local gui: ScreenGui = game.ReplicatedStorage.Shared.HoverCard:Clone()
			gui.Card.Visible = false

			local pos = UserInputService:GetMouseLocation()
			gui.Card.ImageLabel.ItemTip.Text = tip
			tooltipRef.current = gui
			local fx, fy = pos.X + 12, pos.Y + 12
			gui.Card.Position = UDim2.new(0, fx, 0, fy)

			resconnRef.current = RunService.RenderStepped:Connect(function()
				gui.Parent = game.Players.LocalPlayer.PlayerGui
				pos = UserInputService:GetMouseLocation()

				fx, fy = pos.X + 12, pos.Y + 12
				local sizeX, sizeY = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
				local validX, validY = fx + gui.Card.AbsoluteSize.X < sizeX, fy + gui.Card.AbsoluteSize.Y < sizeY
				fx, fy = validX and fx or pos.X - 12, validY and fy or pos.Y - 12
				gui.Card.AnchorPoint = Vector2.new(validX and 0 or 1, validY and 0 or 1)
				gui.Card.Position = UDim2.new(0, fx, 0, fy)
				gui.Card.Visible = true
			end)
		end

		return function()
			if tooltipRef.current then
				tooltipRef.current:Destroy()
				tooltipRef.current = nil
			end
			if resconnRef.current then
				resconnRef.current:Disconnect()
				resconnRef.current = nil
			end
		end
	end, { mouseEnter })

	return e("ImageLabel", {
		Size = Size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		ref = frameRef,
		ZIndex = 2,
		Image = "rbxassetid://136242854116857",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(30, 30, 90, 90),
		ImageColor3 = props.Selected and Color3.new(1, 0, 0)
			or props.Placed and Color3.new(1, 1, 0.6)
			or Color3.new(1, 1, 1),
	}, {
		TextButton = e("TextButton", {
			Size = Size,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1, --(props.Selected or props.Placed) and 0.4 or 0.9,
			-- BackgroundColor3 = props.Selected and Color3.new(1, 0, 0)
			-- 	or props.Placed and Color3.new(1, 1, 0.6)
			-- 	or Color3.new(1, 1, 1),
			TextStrokeTransparency = 0,
			BorderSizePixel = 0,
			Font = "FredokaOne",
			TextSize = 14,
			TextWrapped = true,
			Text = text,
			RichText = true,
			TextColor3 = Color3.new(1, 1, 1),
			ClipsDescendants = true,
			ref = function(textbutton: TextButton)
				if not textbutton then
					return
				end
				textbutton:SetAttribute("UID", props.UID)
			end,
			[React.Event.Activated] = props.clicked,
			[React.Event.MouseEnter] = itemConfigs[props.Item.ItemId]
				and itemConfigs[props.Item.ItemId].ItemTip
				and function(textbutton: TextButton, x, y)
					setMouseEnter(true)
				end,
			[React.Event.MouseLeave] = itemConfigs[props.Item.ItemId]
				and itemConfigs[props.Item.ItemId].ItemTip
				and function()
					setMouseEnter(false)
				end,
			ZIndex = 4,
		}, props.Children),
	})
end

return PICell
