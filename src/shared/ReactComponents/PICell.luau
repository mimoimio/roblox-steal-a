local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local TS = game:GetService("TweenService")
local useToast = require(game.ReplicatedStorage.Shared.ReactComponents.Toasts).useToast

local itemConfigs = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local variationConfigs = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
local tierConfigs = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)

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
		ref = frameRef,
		ZIndex = 2,
	}, {
		TextButton = e("TextButton", {
			Size = Size,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = (props.Selected or props.Placed) and 0.4 or 0.9,
			BackgroundColor3 = props.Selected and Color3.new(1, 0, 0)
				or props.Placed and Color3.new(1, 1, 0.6)
				or Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Font = "FredokaOne",
			TextSize = 14,
			TextWrapped = true,
			Text = text,
			--  props.Item.DisplayName .. "\n" .. props.Item.Rate .. "/s",
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
			ZIndex = 4,
		}, props.Children),
	})
end

return PICell
