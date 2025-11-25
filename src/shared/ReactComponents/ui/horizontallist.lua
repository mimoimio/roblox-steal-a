local React = require(game.ReplicatedStorage.Packages.React)

local function rounded(props)
	return React.createElement("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
	})
end

return rounded
