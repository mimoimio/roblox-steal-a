local React = require(game.ReplicatedStorage.Packages.React)
local rounded = require(script.Parent.ui.rounded)
local padding = require(script.Parent.ui.padding)

local TS = game:GetService("TweenService")

local OPEN_SIZE = UDim2.new(1, 0, 1, 0)
local CLOSED_SIZE = UDim2.new(0, 0, 0, 0)

local function Mustard(props)
	local Phase: "opening" | "open" | "closing" | "closed", setPhase = React.useState("closed")
	local visible, setVisible = React.useState(Phase ~= "closed")

	local children = {
		padding = React.createElement(padding),
		verticallist = React.createElement("UIGridLayout", {
			CellSize = UDim2.new(0, 100, 0, 100),
			CellPadding = UDim2.new(0, 8, 0, 8),
			FillDirectionMaxCells = 2,
		}),
	}

	local animDur = 0.4
	local FrameRef = React.useRef()
	local tweenRef = React.useRef(nil)

	React.useEffect(function()
		local sound = Instance.new("Sound", game.Players.LocalPlayer)
		sound.SoundId = "rbxassetid://74120482730232"
		local c = sound.IsLoaded or sound.Loaded:Wait()
		sound.TimePosition = 0.4

		local frame = FrameRef.current
		if not frame then
			return
		end

		-- Cancel previous tween if any
		if tweenRef.current then
			tweenRef.current:Cancel()
			tweenRef.current = nil
		end

		if props.MustardOpen then
			setPhase("opening")
			setVisible(true) -- show immediately
			local tween = TS:Create(
				frame,
				TweenInfo.new(animDur, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
				{ Size = OPEN_SIZE, BackgroundTransparency = 0 }
			)
			tweenRef.current = tween
			tween.Completed:Connect(function(playbackState)
				if playbackState == Enum.PlaybackState.Completed then
					setPhase("open")
				end
			end)
			tween:Play()
			task.spawn(function()
				sound:Play()
				sound.Ended:Wait()
				sound:Destroy()
			end)
		else
			sound:Destroy()
			setPhase("closing")
			local tween = TS:Create(frame, TweenInfo.new(animDur), { Size = CLOSED_SIZE })
			tweenRef.current = tween
			tween.Completed:Connect(function(playbackState)
				if playbackState == Enum.PlaybackState.Completed then
					setPhase("closed")
					setVisible(false) -- hide after close finishes
				end
			end)
			tween:Play()
		end
	end, { props.MustardOpen })

	return React.createElement("Frame", {
		Size = CLOSED_SIZE,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(0, 0.2, 0.2),
		BackgroundTransparency = 1,
		Active = true,
		Visible = visible,
		ref = FrameRef,
	}, {
		ImageLabel = React.createElement("ImageLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			ImageTransparency = 0,
			BorderSizePixel = 0,
			Image = "rbxassetid://121212267160037",
		}),
		-- UISizeConstraint = React.createElement("UISizeConstraint", {
		-- 	MaxSize = Vector2.new(720, 480),
		-- }),
	})
end

return Mustard
