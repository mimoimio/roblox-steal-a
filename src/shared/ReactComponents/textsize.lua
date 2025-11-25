local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function textsize(props: { Min: number, Max: number })
	local Min = props.Min or 16
	local Max = props.Max or 16
	return e("UITextSizeConstraint", { MaxTextSize = Max, MinTextSize = Min })
end

return textsize
