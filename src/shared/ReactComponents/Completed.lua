local React = require(game.ReplicatedStorage.Packages.React)
local useState = React.useState
local useEffect = React.useEffect
local Players = game:GetService("Players")
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)

local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type PlayerData = sharedtypes.PlayerData

local player = Players.LocalPlayer

type CompletedProps = {
	PlayerData: PlayerData,
}

local getAnimatedText = require(script.Parent.Utils.getAnimatedText)

local function formatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)

	if hours > 0 then
		return string.format("%dh %02dm %02ds", hours, minutes, secs)
	elseif minutes > 0 then
		return string.format("%dm %02ds", minutes, secs)
	else
		return string.format("%ds", secs)
	end
end

local function Completed(props: CompletedProps)
	local wave, setWave = useState(0)
	local visible, setVisible = useState(true)

	-- Animate text wave
	useEffect(function()
		local running = true
		local thread = task.spawn(function()
			while running do
				task.wait(0.1)
				setWave(function(prevWave)
					return prevWave + 1
				end)
			end
		end)
		return function()
			running = false
			task.cancel(thread)
		end
	end, {})

	if not visible then
		return nil
	end

	-- Calculate elapsed time
	local startTime = props.PlayerData.StartTime or 0
	local completedTime = props.PlayerData.CompletedTime or tick()
	local elapsedTime = completedTime - startTime

	-- Format stats
	local timeText = formatTime(elapsedTime)
	local moneyText = props.PlayerData.CompletedMoney and Alyanum.new(props.PlayerData.CompletedMoney):toString() or "0"

	local victoryMessage = string.format(
		[[🎉 <font color="#FFD700">CONGRATULATIONS!</font> 🎉

You've completed Untitled Witch Tycoon!
⏱️ Time: <font color="#00FF88">%s</font>
💰 Total Money: <font color="#FFD700">$%s</font>

<font size="16">Well done, Grand Witch of Commerce! 🧙‍♀️✨</font>]],
		timeText,
		moneyText
	)

	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 100,
	}, {
		-- Center modal
		Modal = React.createElement("ImageLabel", {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.8, 0, 0, 300),
			BackgroundTransparency = 1,
			Image = "rbxassetid://136242854116857",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(30, 30, 90, 90),
			ImageColor3 = Color3.fromRGB(80, 40, 100),
		}, {
			UIGradient = React.createElement("UIGradient", {
				Color = ColorSequence.new(Color3.fromRGB(150, 100, 200), Color3.fromRGB(100, 50, 150)),
				Rotation = 45,
			}),
			UIListLayout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 16),
			}),
			rounded = React.createElement(require(script.Parent.ui.rounded)),
			padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 30),
				PaddingRight = UDim.new(0, 30),
				PaddingTop = UDim.new(0, 30),
				PaddingBottom = UDim.new(0, 30),
			}),

			-- Animated text label
			TextLabel = React.createElement("TextLabel", {
				-- Size = UDim2.new(1, 0, 1, -60),
				AutomaticSize = Enum.AutomaticSize.XY,
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				Font = Enum.Font.FredokaOne,
				TextSize = 20,
				Text = getAnimatedText(victoryMessage, wave),
				TextColor3 = Color3.new(1, 1, 1),
				TextWrapped = true,
				RichText = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextStrokeTransparency = 0.5,
				TextStrokeColor3 = Color3.new(0, 0, 0),
			}),

			-- Continue button
			ContinueButton = React.createElement("TextButton", {
				-- Size = UDim2.new(0.6, 0, 0, 50),
				AutomaticSize = Enum.AutomaticSize.XY,
				Position = UDim2.new(0.5, 0, 1, -50),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(100, 200, 100),
				BorderSizePixel = 0,
				Font = Enum.Font.FredokaOne,
				TextSize = 24,
				Text = "Continue Playing",
				TextColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					setVisible(false)
				end,
				LayoutOrder = 2,
			}, {
				rounded = React.createElement(require(script.Parent.ui.rounded)),
				UIStroke = React.createElement("UIStroke", {
					Color = Color3.fromRGB(50, 150, 50),
					Thickness = 3,
				}),
			}),

			-- Confetti/sparkle effect placeholder
			-- You can add particle emitters here later
		}),

		UISizeConstraint = React.createElement("UISizeConstraint", {
			MaxSize = Vector2.new(800, 500),
		}),
	})
end

return Completed
