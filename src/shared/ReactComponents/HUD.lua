local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local SpecialEventsConfig = require(game.ReplicatedStorage.Shared.Configs.SpecialEventsConfig)
local TS = game:GetService("TweenService")

local function HUD(props)
	local hudRef = React.useRef()

	local PlayerData = props.PlayerData or {}
	local Resources = PlayerData.Resources or {}
	local rate, setRate = React.useState(Resources.Rate)
	local money, setMoney = React.useState(Resources.Money)
	local clock, setClock = React.useState(game.Lighting.ClockTime)

	-- Special events state
	local specialEvents, setSpecialEvents = React.useState({})

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
		local Events = game.ReplicatedStorage.Shared.Events
		local ResourcesUpdated: RemoteEvent = Events:WaitForChild("ResourcesUpdated")
		local SpecialEvents: RemoteEvent = Events:WaitForChild("SpecialEvents")
		local MoneyDisplayUpdate: UnreliableRemoteEvent = Events:WaitForChild("MoneyDisplayUpdate")

		local connections = {
			rupdatec = ResourcesUpdated.OnClientEvent:Connect(function(resources: { Money: number, Rate: number })
				setRate(resources.Rate)
			end),
			seconn = SpecialEvents.OnClientEvent:Connect(function(events)
				setSpecialEvents(events or {})
			end),
			MoneyDisplayUpdate = MoneyDisplayUpdate.OnClientEvent:Connect(function(money, rate)
				if not money then
					return
				end
				setMoney(money)
				setRate(rate)
			end),
		}
		-- On first mount, invoke GetSpecialEvents
		local GetSpecialEvents: RemoteFunction = Events:WaitForChild("GetSpecialEvents")
		local ok, events = pcall(function()
			return GetSpecialEvents:InvokeServer()
		end)
		if ok and type(events) == "table" then
			setSpecialEvents(events)
		end

		return function()
			for i, conn in connections do
				conn:Disconnect()
			end
		end
	end, {})

	React.useState(function()
		local running = true
		task.spawn(function()
			while running do
				local s = ([[%02d:%02d]]):format(game.Lighting.ClockTime, (game.Lighting.ClockTime % 1) * 60)
				setClock(s)
				task.wait(1)
			end
		end)
		return function()
			running = false
		end
	end, {})

	local eventLabels = {
		rounded = e(require(script.Parent.ui.rounded)),

		UIListLayout = e("UIListLayout", {
			SortOrder = "LayoutOrder",
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalFlex = "Fill",
			Padding = UDim.new(0, 10),
		}),
	}
	local eventCount = 0
	local sevents = ""
	for eventId, _ in specialEvents do
		eventCount += 1
		local seventConfig = SpecialEventsConfig[eventId]
		sevents ..= "\n" .. ([[<font color="#%s">%s</font>]]):format(
			seventConfig and seventConfig.ColorPrimary and seventConfig.ColorPrimary:ToHex() or "ffffff",
			seventConfig and seventConfig.DisplayName or eventId
		)
	end

	eventLabels["eventId"] = e("TextLabel", {
		Name = "EventLabel",
		BackgroundTransparency = 1,
		Font = "FredokaOne",
		TextSize = 24,
		RichText = true,
		TextStrokeTransparency = 0,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeColor3 = Color3.new(0, 0, 0),
		Text = sevents:len() > 0 and "Events: " .. sevents or "",
		-- TextColor3 = Color3.new(1, 0.9, 0.3),
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = eventCount,
	})

	return e("Frame", {
		Name = "HUD",
		BackgroundTransparency = 01,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Active = false,
		ref = hudRef,
		ZIndex = 0,
	}, {
		RightHud = e("Frame", {
			Name = "RightHud",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.new(0.25, 0, 0.75, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			UISizeConstraint = e("UISizeConstraint", {
				MaxSize = Vector2.new(100, 300),
			}),
			UIListLayout = e("UIListLayout", {
				SortOrder = "LayoutOrder",
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				VerticalFlex = "Fill",
				HorizontalFlex = "Fill",
				Padding = UDim.new(0, 10),
			}),
			InventoryButton = e("ImageButton", {
				Name = "InventoryButton",
				Position = UDim2.new(0.5, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				LayoutOrder = 1,
				[React.Event.Activated] = props.OnInventoryButtonClick,
			}, {
				rounded = e(require(script.Parent.ui.rounded)),
				TextLabel = e("TextLabel", {
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
				AmountLabel = e("TextLabel", {
					Position = UDim2.new(0, 0, 0, 0),
					Size = UDim2.new(0, 50, 0, 50),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Font = "FredokaOne",
					TextSize = 14,
					Text = (props.ItemAmt or 0) .. "/24",
					Active = false,
					TextStrokeColor3 = Color3.new(0, 0, 0),
					TextStrokeTransparency = 0,
					TextColor3 = Color3.new(1, 1, 1),
				}),
			}),
			SettingsButton = e("ImageButton", {
				Name = "SettingsButton",
				Position = UDim2.new(0.5, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				[React.Event.Activated] = props.OnSettingsButtonClick,
			}, {
				rounded = e(require(script.Parent.ui.rounded)),
				TextLabel = e("TextLabel", {
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
			MusicButton = e("ImageButton", {
				Name = "SettingsButton",
				Position = UDim2.new(0.5, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				LayoutOrder = 2,
				[React.Event.Activated] = props.OnMusicButtonClick,
			}, {
				rounded = e(require(script.Parent.ui.rounded)),
				TextLabel = e("TextLabel", {
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
		TopRightHud = e("ImageLabel", {
			Name = "TopRightHud",
			Image = "rbxassetid://136242854116857",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(30, 30, 90, 90),
			AnchorPoint = Vector2.new(01, 0),
			Position = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
			}),
			verticallist = e(require(script.Parent.ui.verticallist)),
			TextLabel = e("TextLabel", {
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Font = "FredokaOne",
				TextSize = 14,
				TextStrokeTransparency = 0,
				Text = "Money:"
					.. (money and (Alyanum.new(money):toString() .. "/s") or "...")
					.. "\nrate: "
					.. (rate and (Alyanum.new(rate):toString() .. "/s") or "..."),
				Active = false,
				TextColor3 = Color3.new(1, 1, 1),
			}),
		}),
		BotLeftHud = e("ImageLabel", {
			Name = "TopRightHud",
			Image = "rbxassetid://136242854116857",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(30, 30, 90, 90),
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
			}),
			verticallist = e(require(script.Parent.ui.verticallist)),
			TextLabel = e("TextLabel", {
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Font = "FredokaOne",
				TextSize = 14,
				TextStrokeTransparency = 0,
				Text = clock,
				Active = false,
				TextColor3 = Color3.new(1, 1, 1),
			}),
		}),
		-- Special event labels (direct children of HUD)
		TopHud = e("Frame", {
			Name = "TopHud",
			Position = UDim2.new(0.5, 0, 0, 0),
			Size = UDim2.new(0, 200, 0, 50),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, eventLabels),
	})
end
return HUD
