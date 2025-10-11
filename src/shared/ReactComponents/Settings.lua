local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type PlayerData = sharedtypes.PlayerData

local React = require(game.ReplicatedStorage.Packages.React)
local TS = game:GetService("TweenService")

local OPEN_POS = UDim2.new(0.5, 0, 0.5, 0)
local CLOSED_POS = UDim2.new(0.5, 0, -0.5, 0)

local function Settings(props: {
	SettingsOpen: boolean,
	PlayerData: PlayerData,
})
	local Phase: "opening" | "open" | "closing" | "closed", setPhase = React.useState("closed")
	local visible, setVisible = React.useState(Phase ~= "closed")

	local animDur = 0.4
	local FrameRef = React.useRef()
	local tweenRef = React.useRef(nil)

	React.useEffect(function()
		local frame = FrameRef.current
		if not frame then
			return
		end

		-- Cancel previous tween if any
		if tweenRef.current then
			tweenRef.current:Cancel()
			tweenRef.current = nil
		end

		if props.SettingsOpen then
			setPhase("opening")
			setVisible(true) -- show immediately
			local tween = TS:Create(frame, TweenInfo.new(animDur), { Position = OPEN_POS })
			tweenRef.current = tween
			tween.Completed:Connect(function(playbackState)
				if playbackState == Enum.PlaybackState.Completed then
					setPhase("open")
				end
			end)
			tween:Play()
		else
			setPhase("closing")
			local tween = TS:Create(frame, TweenInfo.new(animDur), { Position = CLOSED_POS })
			tweenRef.current = tween
			tween.Completed:Connect(function(playbackState)
				if playbackState == Enum.PlaybackState.Completed then
					setPhase("closed")
					setVisible(false) -- hide after close finishes
				end
			end)
			tween:Play()
		end
	end, { props.SettingsOpen })

	return React.createElement("Frame", {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 400, 0, 300),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = visible,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ref = FrameRef,
	}, {
		-- TextButton = React.createElement("TextButton", {
		-- 	Size = UDim2.new(0, 100, 0, 50),
		-- 	Text = "Music",
		-- 	BackgroundColor3 = props.PlayerData.PlayerSettings
		-- 			and props.PlayerData.PlayerSettings.MusicMuted
		-- 			and Color3.new(0.2, 0.2, 0.2)
		-- 		or Color3.new(0, 0.6, 0),
		-- 	Font = "FredokaOne",
		-- 	TextSize = 14,
		-- 	TextColor3 = Color3.new(1, 1, 1),

		-- 	[React.Event.Activated] = props.OnToggleMute,
		-- }, {
		-- 	rounded = React.createElement(require(script.Parent.ui.rounded)),
		-- }),

		WipeButton = React.createElement("TextButton", {
			Size = UDim2.new(0, 100, 0, 50),
			Position = UDim2.new(0, 110, 0, 0),
			Text = "Wipe Data\n(Playtester tool)",
			BackgroundColor3 = Color3.new(0.8, 0.2, 0.2),
			Font = "FredokaOne",
			TextSize = 14,
			TextColor3 = Color3.new(1, 1, 1),
			[React.Event.Activated] = function()
				game.ReplicatedStorage.Shared.Events.Wipe:FireServer()
			end,
		}, {
			rounded = React.createElement(require(script.Parent.ui.rounded)),
		}),

		padding = React.createElement(require(script.Parent.ui.padding)),
		rounded = React.createElement(require(script.Parent.ui.rounded)),
	})
end

return Settings
