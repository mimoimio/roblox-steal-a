local React = require(game.ReplicatedStorage.Packages.React)
local TS = game:GetService("TweenService")

local function HUD(props)
	local hudRef = React.useRef()

	local PlayerData = props.PlayerData or {}
	local Resources = PlayerData.Resources or {}
	local rate, setRate = React.useState(Resources.Rate)

	React.useEffect(function()
		if hudRef.current then
			warn(hudRef.current);
			(hudRef.current :: Frame).Changed:Connect(function(property)
				if property == "AbsoluteSize" then
					warn("AbsoluteSize changed:", hudRef.current[property])
				end
			end)
		else
			warn("no hudref", hudRef.current)
		end

		local ResourcesUpdated: RemoteEvent = game.ReplicatedStorage.Shared.Events:WaitForChild("ResourcesUpdated")
		local rupdatec = ResourcesUpdated.OnClientEvent:Connect(function(resources: { Money: number, Rate: number })
			setRate(resources.Rate)
		end)

		return function()
			if rupdatec then
				rupdatec:Disconnect()
			end
		end
	end, {})
	return React.createElement("Frame", {
		Name = "HUD",
		BackgroundTransparency = 01,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Active = false,
		ref = hudRef,
		ZIndex = 0,
	}, {
		RightHud = React.createElement("Frame", {
			Name = "RightHud",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.new(0.25, 0, 0.75, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			UISizeConstraint = React.createElement("UISizeConstraint", {
				MaxSize = Vector2.new(100, 300),
			}),
			UIListLayout = React.createElement("UIListLayout", {
				SortOrder = "LayoutOrder",
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				VerticalFlex = "Fill",
				HorizontalFlex = "Fill",
				Padding = UDim.new(0, 10),
			}),
			InventoryButton = React.createElement("ImageButton", {
				Name = "InventoryButton",
				Position = UDim2.new(0.5, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				LayoutOrder = 1,
				[React.Event.Activated] = props.OnInventoryButtonClick,
			}, {
				rounded = React.createElement(require(script.Parent.ui.rounded)),
				TextLabel = React.createElement("TextLabel", {
					Position = UDim2.new(0.5, 0, 1, -8),
					Size = UDim2.new(1, 0, 1, 0),
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundTransparency = 1,
					Font = "FredokaOne",
					TextSize = 14,
					Text = "Inventory [E]",
					Active = false,
					TextColor3 = Color3.new(1, 1, 1),
				}),
			}),
			SettingsButton = React.createElement("ImageButton", {
				Name = "SettingsButton",
				Position = UDim2.new(0.5, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				[React.Event.Activated] = props.OnSettingsButtonClick,
			}, {
				rounded = React.createElement(require(script.Parent.ui.rounded)),
				TextLabel = React.createElement("TextLabel", {
					Position = UDim2.new(0.5, 0, 1, -8),
					Size = UDim2.new(1, 0, 01, 0),
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundTransparency = 1,
					Font = "FredokaOne",
					TextSize = 14,
					Text = "Settings [C]",
					Active = false,
					TextColor3 = Color3.new(1, 1, 1),
				}),
			}),
			MusicButton = React.createElement("ImageButton", {
				Name = "SettingsButton",
				Position = UDim2.new(0.5, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				LayoutOrder = 2,
				[React.Event.Activated] = props.OnMusicButtonClick,
			}, {
				rounded = React.createElement(require(script.Parent.ui.rounded)),
				TextLabel = React.createElement("TextLabel", {
					Position = UDim2.new(0.5, 0, 1, -8),
					Size = UDim2.new(1, 0, 01, 0),
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundTransparency = 1,
					Font = "FredokaOne",
					TextSize = 14,
					Text = "Music [N]",
					Active = false,
					TextColor3 = Color3.new(1, 1, 1),
				}),
			}),
		}),
		TopRightHud = React.createElement("Frame", {
			Name = "TopRightHud",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0, 300, 0, 50),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			-- Frame = React.createElement("Frame", {
			-- 	Position = UDim2.new(0.5, 0, 0, 0),
			-- 	AnchorPoint = Vector2.new(0.5, 0),
			-- 	BackgroundTransparency = 0.4,
			-- 	BorderSizePixel = 0,
			-- 	LayoutOrder = 1,
			-- }, {
			rounded = React.createElement(require(script.Parent.ui.rounded)),
			TextLabel = React.createElement("TextLabel", {
				Position = UDim2.new(0.5, 0, 0, -8),
				AutomaticSize = Enum.AutomaticSize.XY,
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Font = "FredokaOne",
				TextSize = 14,
				Text = "Money rate: " .. (rate and (rate .. "/s") or "..."),
				Active = false,
				TextColor3 = Color3.new(1, 1, 1),
			}),
			-- }),
		}),
	})
end

return HUD
