local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local TS = game:GetService("TweenService")
local useToast = require(game.ReplicatedStorage.Shared.ReactComponents.Toasts).useToast
-- Props:
--  UID: string
--  DisplayName: string
--  Height: number? (pixel height) default 50
--  TweenTime: number? default 0.25
--  Children? (additional descendants)

local DEFAULT_TWEEN = 0.25
local MOUNTED_SIZE = UDim2.new(1, 0, 1, 0)

local function InventoryItem(props: { isMountedRef: { current: boolean } })
	local frameRef = React.useRef(nil)
	local labelRef = React.useRef(nil)
	local Size, setSize = React.useState(UDim2.new(0, 0, 0, 0))
	local tweenTime = props.TweenTime or DEFAULT_TWEEN
	local toast = useToast()

	React.useEffect(function()
		local label: TextLabel? = labelRef.current
		if not label or not props.isMountedRef or not props.isMountedRef.current then
			setSize(MOUNTED_SIZE)
			return
		end
		-- Start collapsed (Size already set in element props) then tween to full
		local c
		if props.isMountedRef then
			if props.InventoryOpen then
				local tween =
					TS:Create(label, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = MOUNTED_SIZE,
					})
				c = tween.Completed:Connect(function()
					setSize(MOUNTED_SIZE)
				end)
				tween:Play()
			else
				setSize(MOUNTED_SIZE)
			end
		end
		toast.open("+ " .. props.DisplayName)
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
		end
	end, {})

	return e("Frame", {
		Size = Size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		ZIndex = 12,
		ref = frameRef,
	}, {
		TextLabel = e("TextLabel", {
			Size = Size,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			Font = "FredokaOne",
			ZIndex = 13,
			TextSize = 14,
			Text = props.DisplayName,
			TextColor3 = Color3.new(1, 1, 1),
			ClipsDescendants = true,
			ref = labelRef,
		}, props.Children),
	})
end

return InventoryItem
