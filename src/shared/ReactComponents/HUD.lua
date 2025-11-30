local textsize = require(script.Parent.textsize)
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local BeamToNextButton = require(script.Parent.BeamToNextButton)

local function HUD(props)
	local hudRef = React.useRef()
	local clock, setClock = React.useState(game.Lighting.ClockTime)
	-- Stopwatch state and effect (must be inside HUD for React to be defined)
	local stopwatch, setStopwatch = React.useState("00:00")
	React.useEffect(function()
		local running = true
		local elapsed = 0
		task.spawn(function()
			while running do
				local mins = math.floor(elapsed / 60)
				local secs = elapsed % 60
				setStopwatch(string.format("%02d:%02d", mins, secs))
				task.wait(1)
				elapsed += 1
			end
		end)
		return function()
			running = false
		end
	end, {})

	-- Special events state
	local specialEvents, setSpecialEvents = React.useState({})

	React.useEffect(function()
		local Events = game.ReplicatedStorage.Shared.Events
		local SpecialEvents: RemoteEvent = Events:WaitForChild("SpecialEvents")

		local connections = {
			seconn = SpecialEvents.OnClientEvent:Connect(function(events)
				-- setSpecialEvents(events or {})
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

	local ownedItems, setOwnedItems = React.useState({})
	local GeneratedItemConfigs, setGeneratedItemConfigs = React.useState({})
	local totalItemCount, setTotalItemCount = React.useState(0)

	React.useEffect(function()
		local Events = game.ReplicatedStorage.Shared.Events

		-- Get owned items
		local GetOwnedItems: RemoteFunction = Events:WaitForChild("GetOwnedItems") :: { [string]: boolean }
		local owned = GetOwnedItems:InvokeServer()
		if owned and type(owned) == "table" then
			setOwnedItems(owned)
		end
		-- Get itemconfigs
		local GetGeneratedItemConfigs: RemoteFunction = Events:WaitForChild("GetGeneratedItemConfigs")
		local xGeneratedItemConfigs = GetGeneratedItemConfigs:InvokeServer()
		if xGeneratedItemConfigs and type(xGeneratedItemConfigs) == "table" then
			setGeneratedItemConfigs(xGeneratedItemConfigs)
			setTotalItemCount(#xGeneratedItemConfigs)
		end

		-- Listen for updates to owned items
		local OwnedItemsUpdated: RemoteEvent = Events:WaitForChild("OwnedItemsUpdated")
		local connection = OwnedItemsUpdated.OnClientEvent:Connect(function(newOwned)
			if newOwned and type(newOwned) == "table" then
				setOwnedItems(newOwned)
			end
		end)

		return function()
			if connection then
				connection:Disconnect()
			end
		end
	end, {})

	local ownedCount = 0
	if ownedItems then
		for i, itemconfig in GeneratedItemConfigs do
			if not ownedItems[itemconfig.ItemId] then
				continue
			end
			ownedCount = ownedCount + 1
		end
	end

	local progress = totalItemCount > 0 and (ownedCount / totalItemCount) or 0
	local showProgress, setShowProgress = React.useState(true)

	return e("Frame", {
		Name = "HUD",
		BackgroundTransparency = 01,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Active = false,
		ref = hudRef,
		ZIndex = 0,
	}, {
		-- RightHud = e("Frame", {
		-- 	Visible = props.activePanel == "none",
		-- 	Name = "RightHud",
		-- 	AnchorPoint = Vector2.new(1, 0.5),
		-- 	Position = UDim2.new(1, 0, 0.5, 0),
		-- 	Size = UDim2.new(0.25, 0, 0.75, 0),
		-- 	BackgroundTransparency = 1,
		-- 	BorderSizePixel = 0,
		-- }, {
		-- 	UISizeConstraint = e("UISizeConstraint", {
		-- 		MaxSize = Vector2.new(100, 300),
		-- 	}),
		-- 	UIListLayout = e("UIListLayout", {
		-- 		SortOrder = "LayoutOrder",
		-- 		FillDirection = Enum.FillDirection.Vertical,
		-- 		ItemLineAlignment = Enum.ItemLineAlignment.Center,
		-- 		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		-- 		VerticalAlignment = Enum.VerticalAlignment.Center,
		-- 		VerticalFlex = Enum.UIFlexAlignment.None,
		-- 		HorizontalFlex = "Fill",
		-- 		Padding = UDim.new(0, 10),
		-- 	}),
		-- 	InventoryButton = e("ImageButton", {
		-- 		Name = "InventoryButton",
		-- 		AnchorPoint = Vector2.new(0.5, 0),
		-- 		Size = UDim2.new(1, 0, 1, 0),
		-- 		BackgroundTransparency = 0.4,
		-- 		BorderSizePixel = 0,
		-- 		LayoutOrder = 1,
		-- 		[React.Event.Activated] = props.OnInventoryButtonClick,
		-- 	}, {
		-- 		UISizeConstraint = e("UISizeConstraint", {
		-- 			MaxSize = Vector2.new(80, 80),
		-- 		}),
		-- 		rounded = e(require(script.Parent.ui.rounded)),
		-- 		TextLabel = e("TextLabel", {
		-- 			Position = UDim2.new(0.5, 0, 1, -8),
		-- 			Size = UDim2.new(1, 0, 1, 0),
		-- 			AnchorPoint = Vector2.new(0.5, 1),
		-- 			BackgroundTransparency = 1,
		-- 			Font = "FredokaOne",
		-- 			TextSize = 12,
		-- 			Text = "Inventory [E]",
		-- 			Active = false,
		-- 			TextColor3 = Color3.new(1, 1, 1),
		-- 		}, {
		-- 			UITextSizeConstraint = e(textsize, { Min = 12, Max = 12 }),
		-- 		}),
		-- 		AmountLabel = e("TextLabel", {
		-- 			Position = UDim2.new(0, 0, 0, 0),
		-- 			Size = UDim2.new(0, 50, 0, 50),
		-- 			AnchorPoint = Vector2.new(0.5, 0.5),
		-- 			BackgroundTransparency = 1,
		-- 			Font = "FredokaOne",
		-- 			TextSize = 14,
		-- 			Text = (props.ItemAmt or 0) .. "/24",
		-- 			Active = false,
		-- 			TextStrokeColor3 = Color3.new(0, 0, 0),
		-- 			TextStrokeTransparency = 0,
		-- 			TextColor3 = Color3.new(1, 1, 1),
		-- 		}, {
		-- 			UITextSizeConstraint = e(textsize, { Min = 12, Max = 12 }),
		-- 		}),
		-- 	}),
		-- 	RebirthButton = props.PlayerData.GameCompleted and React.createElement("ImageButton", {
		-- 		Size = UDim2.new(1, 0, 1, 0),
		-- 		BackgroundColor3 = Color3.fromRGB(200, 50, 50),
		-- 		BorderSizePixel = 0,
		-- 		[React.Event.Activated] = function()
		-- 			game.ReplicatedStorage.Shared.Events.Wipe:FireServer()
		-- 		end,
		-- 	}, {
		-- 		UISizeConstraint = e("UISizeConstraint", {
		-- 			MaxSize = Vector2.new(80, 80),
		-- 		}),
		-- 		rounded = React.createElement(require(script.Parent.ui.rounded)),
		-- 		TextLabel = React.createElement("TextLabel", {
		-- 			Size = UDim2.new(1, 0, 1, 0),
		-- 			BackgroundTransparency = 1,
		-- 			Text = "Rebirth (+5%)",
		-- 			Font = "FredokaOne",
		-- 			TextSize = 14,
		-- 			TextColor3 = Color3.new(1, 1, 1),
		-- 			TextXAlignment = Enum.TextXAlignment.Center,
		-- 		}, {
		-- 			UITextSizeConstraint = e(textsize, { Min = 12, Max = 12 }),
		-- 		}),
		-- 	}) or nil,
		-- 	ShopButton = e("ImageButton", {
		-- 		Name = "ShopButton",
		-- 		Size = UDim2.new(1, 0, 1, 0),
		-- 		AnchorPoint = Vector2.new(0.5, 0),
		-- 		BackgroundTransparency = 0.4,
		-- 		BorderSizePixel = 0,
		-- 		LayoutOrder = 3,
		-- 		[React.Event.Activated] = props.OnShopButtonClick,
		-- 	}, {
		-- 		UISizeConstraint = e("UISizeConstraint", {
		-- 			MaxSize = Vector2.new(80, 80),
		-- 		}),
		-- 		rounded = e(require(script.Parent.ui.rounded)),
		-- 		TextLabel = e("TextLabel", {
		-- 			Position = UDim2.new(0.5, 0, 1, -8),
		-- 			Size = UDim2.new(1, 0, 01, 0),
		-- 			AnchorPoint = Vector2.new(0.5, 1),
		-- 			BackgroundTransparency = 1,
		-- 			Font = "FredokaOne",
		-- 			TextSize = 14,
		-- 			Text = "Shop [G]",
		-- 			Active = false,
		-- 			TextColor3 = Color3.new(1, 1, 1),
		-- 		}, {
		-- 			UITextSizeConstraint = e(textsize, { Min = 12, Max = 12 }),
		-- 		}),
		-- 	}),
		-- }),
		BotLeftHud = e("ImageLabel", {
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
			-- StopwatchLabel = e("TextLabel", {
			-- 	Position = UDim2.new(0.5, 0, 1, 0),
			-- 	AutomaticSize = Enum.AutomaticSize.XY,
			-- 	AnchorPoint = Vector2.new(0.5, 1),
			-- 	BackgroundTransparency = 1,
			-- 	Font = "FredokaOne",
			-- 	TextSize = 14,
			-- 	TextStrokeTransparency = 0,
			-- 	Text = stopwatch,
			-- 	Active = false,
			-- 	TextColor3 = Color3.new(1, 1, 1),
			-- }),
		}),

		-- Special event labels (direct children of HUD)
		BottomHud = e("Frame", {
			Name = "BottomHud",
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(0, 200, 0, 50),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			BeamToggle = (props.PlayerData.TutorialFinished and props.SHOWBEAM)
					and e(BeamToNextButton, { props.activePanel })
				or nil,
		}),

		TopHud = e("Frame", {
			Name = "TopHud",
			Position = UDim2.new(0.5, 0, 0, -66),
			Size = UDim2.new(0, 200, 0, 50),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			ShowProgressButton = not showProgress
					and props.activePanel == "none"
					and React.createElement("TextButton", {
						Size = UDim2.new(0, 40, 0, 40),
						Position = UDim2.new(0.5, 0, 0, 0),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundColor3 = Color3.fromRGB(80, 80, 80),
						BackgroundTransparency = 0.3,
						BorderSizePixel = 0,
						Text = "👁️",
						Font = "FredokaOne",
						TextSize = 20,
						[React.Event.Activated] = function()
							setShowProgress(true)
						end,
					}, {
						rounded = React.createElement(require(script.Parent.ui.rounded)),
					})
				or nil,
			ProgressContainer = showProgress and props.activePanel == "none" and React.createElement("Frame", {
				Size = UDim2.new(0, 350, 0, 80),
				Position = UDim2.new(0.5, 0, 0, 70),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
			}, {
				HideButton = React.createElement("TextButton", {
					Size = UDim2.new(0, 30, 0, 30),
					Position = UDim2.new(1, 5, 0, 0),
					AnchorPoint = Vector2.new(0, 0),
					BackgroundColor3 = Color3.fromRGB(60, 60, 60),
					BackgroundTransparency = 0.3,
					BorderSizePixel = 0,
					Text = "👁️",
					Font = "FredokaOne",
					TextSize = 18,
					TextColor3 = Color3.new(1, 1, 1),
					[React.Event.Activated] = function()
						setShowProgress(false)
					end,
				}, {
					rounded = React.createElement(require(script.Parent.ui.rounded)),
				}),
				-- Title = React.createElement("TextLabel", {
				-- 	Size = UDim2.new(1, 0, 0, 20),
				-- 	Position = UDim2.new(0, 0, 0, 0),
				-- 	BackgroundTransparency = 1,
				-- 	Text = "Collection Progress",
				-- 	Font = "FredokaOne",
				-- 	TextSize = 16,
				-- 	TextColor3 = Color3.new(1, 1, 1),
				-- 	TextXAlignment = Enum.TextXAlignment.Center,
				-- }),

				ProgressBarBackground = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 30),
					Position = UDim2.new(0, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(40, 40, 40),
					BorderSizePixel = 0,
				}, {
					ProgressBar = React.createElement("Frame", {
						Size = UDim2.new(progress, 0, 1, 0),
						BackgroundColor3 = Color3.fromRGB(100, 200, 100),
						BorderSizePixel = 0,
						ZIndex = 1,
					}, {
						rounded = React.createElement(require(script.Parent.ui.rounded)),
					}),
					rounded = React.createElement(require(script.Parent.ui.rounded)),
					ProgressText = React.createElement("TextLabel", {
						-- AutomaticSize = Enum.AutomaticSize.XY,
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 2,
						Position = UDim2.new(0, 0, 0, 0),
						BackgroundTransparency = 1,
						TextStrokeTransparency = 0,
						Text = string.format("(%.1f%%)", progress * 100),
						Font = "FredokaOne",
						TextSize = 14,
						TextColor3 = Color3.new(1, 1, 1),
						TextXAlignment = Enum.TextXAlignment.Center,
					}),
				}),
			}),
		}),

		MusicButton = e("ImageButton", {
			Name = "SettingsButton",
			Position = UDim2.new(1, 12, 1, 12),
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.XY,
			[React.Event.Activated] = props.OnSettingsButtonClick,
		}, {
			UIListLayout = e("UIListLayout", {
				SortOrder = "LayoutOrder",
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				HorizontalFlex = "Fill",
				Padding = UDim.new(0, 10),
			}),
			padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
			}),
			rounded = e(require(script.Parent.ui.rounded)),
			TextLabel = e("TextLabel", {
				Position = UDim2.new(0.5, 0, 1, -8),
				AutomaticSize = Enum.AutomaticSize.XY,
				-- Size = UDim2.new(1, 0, 01, 0),
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				Font = "FredokaOne",
				TextSize = 14,
				Text = "⚙️[C]",
				Active = false,
				TextColor3 = Color3.new(1, 1, 1),
			}),
		}),
	})
end

return React.memo(function(props)
	return e(HUD, props)
end)
