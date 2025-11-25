local React = require(game.ReplicatedStorage.Packages.React)

local function rounded(props)
	return React.createElement("UIPadding", {
		PaddingBottom = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})
end

return rounded
