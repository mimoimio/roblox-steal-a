local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local RunService = game:GetService("RunService")
local TS = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local useToast = require(game.ReplicatedStorage.Shared.ReactComponents.Toasts).useToast
local DEFAULT_TWEEN = 1
local MOUNTED_SIZE = UDim2.new(1, 0, 1, 0)

local itemConfigs = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local variationConfigs = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
local tierConfigs = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)
local FormatItemLabelText = require(game.ReplicatedStorage.Shared.Utils.Format).FormatItemLabelText

local function InventoryItem(props: { isMountedRef: { current: boolean } })
	local frameRef = React.useRef(nil)
	local labelRef = React.useRef(nil)
	local Size: UDim2?, setSize = React.useState(UDim2.new(0, 0, 0, 0))
	local tweenTime = props.TweenTime or DEFAULT_TWEEN
	local toast = useToast()
	local mouseEnter, setMouseEnter = React.useState(false)

	local tooltipRef = React.useRef(nil)
	local resconnRef = React.useRef(nil)
	React.useEffect(function()
		local label: TextLabel? = labelRef.current
		if not label or not props.isMountedRef or not props.isMountedRef.current then
			setSize(MOUNTED_SIZE)
			return
		end
		-- Start collapsed (Size already set in element props) then tween to full
		local c, cf
		if props.isMountedRef then
			if props.InventoryOpen then
				local tween =
					TS:Create(label, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = MOUNTED_SIZE,
						TextSize = MOUNTED_SIZE.X.Scale * 14,
					})
				c = tween.Completed:Connect(function()
					setSize(MOUNTED_SIZE)
				end)
				tween:Play()
				local tweenframe = TS:Create(
					frameRef.current,
					TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Size = MOUNTED_SIZE,
					}
				)
				cf = tweenframe.Completed:Connect(function()
					setSize(MOUNTED_SIZE)
				end)
				tweenframe:Play()
			else
				setSize(MOUNTED_SIZE)
			end
		end
		toast.open("+ " .. props.Item.DisplayName)
		local sound: Sound = game.ReplicatedStorage.Shared.SFX:FindFirstChild("PickUp")
		if sound then
			task.spawn(function()
				sound = sound:Clone()
				sound.Parent = game.Players.LocalPlayer
				if not sound.IsLoaded then
					sound.Loaded:Wait()
				end
				sound:Play()
				sound.Ended:Wait()
				sound:Destroy()
			end)
		end
		return function()
			if c then
				c:Disconnect()
			end
			if cf then
				cf:Disconnect()
			end
		end
	end, {})

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

	local text = FormatItemLabelText(props.Item)
	return e("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 3,
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
	}, {
		frame = e("ImageLabel", {
			Size = Size,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = props.LayoutOrder,
			ZIndex = 4,
			ref = frameRef,
			Image = "rbxassetid://136242854116857",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(30, 30, 90, 90),
			ImageColor3 = props.Selected and Color3.new(1, 0, 0)
				or props.Placed and Color3.new(1, 1, 0.6)
				or Color3.new(1, 1, 1),
		}, {
			TextLabel = e("TextLabel", {
				Size = Size,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				TextStrokeTransparency = 0,
				BackgroundTransparency = 1, --(props.Selected or props.Placed) and 0.4 or 0.9,
				-- BackgroundColor3 = props.Selected and Color3.new(1, 0, 0)
				-- 	or props.Placed and Color3.new(1, 1, 0.6)
				-- 	or Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Font = "FredokaOne",
				ZIndex = 5,
				TextWrapped = true,
				TextSize = 14 * (Size and Size.X and Size.X.Scale or 0),
				RichText = true,
				Text = text,
				TextColor3 = Color3.new(1, 1, 1),
				ClipsDescendants = true,
				ref = labelRef,
			}, props.Children),
		}),
	})
end

return InventoryItem
