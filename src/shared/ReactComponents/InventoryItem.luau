local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local TS = game:GetService("TweenService")
local useToast = require(game.ReplicatedStorage.Shared.ReactComponents.Toasts).useToast
local DEFAULT_TWEEN = 0.25
local MOUNTED_SIZE = UDim2.new(1, 0, 1, 0)

local itemConfigs = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local variationConfigs = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
local tierConfigs = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)

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
		end
	end, {})

	local cfg = itemConfigs[props.Item.ItemId]
	local varcfg = variationConfigs[props.Item.Variation] or variationConfigs[(props.Item.Variation :: string):lower()]
	local tier = tierConfigs[props.Item.Tier] or tierConfigs[(props.Item.Tier :: string):lower()]

	-- Name, Variation, Tier, and Rate Display
	local name = cfg.DisplayName
	local varColor = varcfg.ColorPrimary:ToHex()
	local varName = varcfg.DisplayName
	local tierColor = tier.ColorPrimary:ToHex()
	local tierName = tier.DisplayName
	local rate = props.Item.Rate

	local text
	if varcfg.VariationId ~= "none" then
		text = --
			([[<stroke color="#000000" thickness="1"><font>%s</font>
<font color="#%s">%s</font> | <font color="#%s">%s</font>
<font>%s/s</font></stroke>]]):format(name, varColor, varName, tierColor, tierName, rate)
	else
		text = --
			([[<stroke color="#000000" thickness="1"><font>%s</font>
<font color="#%s">%s</font>
<font>%s/s</font></stroke>]]):format(name, tierColor, tierName, rate)
	end
	return e("Frame", {
		Size = Size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		ZIndex = 3,
		ref = frameRef,
	}, {
		TextLabel = e("TextLabel", {
			Size = Size,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),

			BackgroundTransparency = (props.Selected or props.Placed) and 0.4 or 0.9,
			BackgroundColor3 = props.Selected and Color3.new(1, 0, 0)
				or props.Placed and Color3.new(1, 1, 0.6)
				or Color3.new(1, 1, 1),			BorderSizePixel = 0,
			Font = "FredokaOne",
			ZIndex = 4,
			TextWrapped = true,
			TextSize = 14,
			RichText = true,
			Text = text,
			TextColor3 = Color3.new(1, 1, 1),
			ClipsDescendants = true,
			ref = labelRef,
		}, props.Children),
	})
end

return InventoryItem
