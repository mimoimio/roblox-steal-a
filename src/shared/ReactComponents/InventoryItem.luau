local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local RunService = game:GetService("RunService")
local TS = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local useToast = require(game.ReplicatedStorage.Shared.ReactComponents.Toasts).useToast
local DEFAULT_TWEEN = 1
local MOUNTED_SIZE = UDim2.new(0.9, 0, 0.9, 0)

local itemConfigs = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local variationConfigs = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
local tierConfigs = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)
local FormatItemLabelText = require(game.ReplicatedStorage.Shared.Utils.Format).FormatItemLabelText

local function InventoryItem(props: { isMountedRef: { current: boolean } })
	local frameRef = React.useRef(nil)
	local labelRef = React.useRef(nil)
	local tbRef = React.useRef(nil)
	local Size: UDim2?, setSize = React.useState(UDim2.new(0, 0, 0, 0))
	local tweenTime = props.TweenTime or DEFAULT_TWEEN
	local toast = useToast()
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
		if props.Selected == props.UID then
			setSize(UDim2.new(1, 0, 1, 0))
		end

		return function()
			setSize(MOUNTED_SIZE)
		end
	end, { props.Selected })

	React.useEffect(function()
		if props.InventoryOpen and props.Selected then
			return
		end

		setSize(MOUNTED_SIZE)

		if tbRef.current ~= nil then
			props.OnDeselect(tbRef.current)
		end
	end)

	local text = FormatItemLabelText(props.Item)
	return e("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 3,
		ref = tbRef,
		[React.Event.Activated] = props.OnSelect,
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
			ImageColor3 = props.Placed and Color3.new(1, 1, 0.6) or Color3.new(1, 1, 1),
		}, {
			UIPadding = e("UIPadding", {
				PaddingTop = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				PaddingLeft = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
			}),
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
				Text = text .. "\n" .. (itemConfigs[props.Item.ItemId] and itemConfigs[props.Item.ItemId].ItemTip),
				TextColor3 = Color3.new(1, 1, 1),
				ClipsDescendants = true,
				ref = labelRef,
			}, props.Children),
			[props.UID] = e("ImageButton", {
				-- AutomaticSize = Enum.AutomaticSize.XY,
				Image = "rbxassetid://136242854116857",
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(30, 30, 90, 90),
				ImageColor3 = Color3.new(0.807843, 0.141176, 0.141176),
				Visible = props.Selected == props.UID,
				Size = UDim2.new(0, 42, 0, 42),
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				ZIndex = 10,
				[React.Event.Activated] = props.sell,
				Position = UDim2.new(1, 0, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
			}, {
				padding = e("UIPadding", {
					PaddingTop = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
					PaddingLeft = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 4),
				}),
				TextLabel = e("TextLabel", {
					BackgroundTransparency = 1,
					Active = false,
					ZIndex = 11,
					Text = "Sell",
					Font = "FredokaOne",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					Size = UDim2.new(1, 0, 1, 0),
				}),
				-- Rounded = e(require(script.Parent.ui.rounded)),
			}),
		}),
	})
end

return InventoryItem
