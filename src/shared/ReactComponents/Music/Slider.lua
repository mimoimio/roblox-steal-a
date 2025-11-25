local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local rounded = require(game.ReplicatedStorage.Shared.ReactComponents.ui.rounded)

local RunService = game:GetService("RunService")

export type SliderProps = {
	initialVolume: number?, -- 0..1
	onVolumeChange: ((number) -> ())?, -- receives 0..1
}

local TRACK_HEIGHT = 200
local HANDLE_HEIGHT = 25

local function Slider(props: SliderProps)
	local open, setOpen = React.useState(false)
	local volume, setVolume = React.useState(props.initialVolume ~= nil and props.initialVolume or 1)

	-- Refs
	local handleRef = React.useRef(nil :: Frame?)
	local detectorRef = React.useRef(nil :: UIDragDetector?)
	local hbConnRef = React.useRef(nil :: RBXScriptConnection?)
	local draggingRef = React.useRef(false)

	local function toggleSlider()
		setOpen(function(prev)
			return not prev
		end)
	end

	-- Push volume changes outward (and fallback to shared.MusicPlayer if provided)
	React.useEffect(function()
		if props.onVolumeChange then
			props.onVolumeChange(volume)
		elseif shared and shared.MusicPlayer and shared.MusicPlayer.setVolume then
			shared.MusicPlayer:setVolume(volume)
		end
	end, { volume })

	-- Keep handle position in sync when NOT dragging (e.g., external volume change)
	React.useEffect(function()
		if draggingRef.current then
			return
		end
		local handle = handleRef.current
		if not handle then
			return
		end
		local y = (1 - volume) * TRACK_HEIGHT
		handle.Position = UDim2.new(0.5, 0, 0, math.clamp(y, 0, TRACK_HEIGHT))
	end, { volume, open })

	-- Cleanup on unmount
	React.useEffect(function()
		return function()
			if hbConnRef.current then
				hbConnRef.current:Disconnect()
				hbConnRef.current = nil
			end
		end
	end, {})

	-- Helpers
	local function beginDrag()
		local handle = handleRef.current
		local detector = detectorRef.current
		if not handle or not detector then
			return
		end

		draggingRef.current = true

		-- Clamp drag travel so handle stays within [0, TRACK_HEIGHT]
		local currentY = handle.Position.Y.Offset
		detector.MinDragTranslation = UDim2.new(0, 0, 0, -currentY)
		detector.MaxDragTranslation = UDim2.new(0, 0, 0, TRACK_HEIGHT - currentY)

		-- Heartbeat loop to read current Y and convert to volume
		if hbConnRef.current then
			hbConnRef.current:Disconnect()
			hbConnRef.current = nil
		end
		hbConnRef.current = RunService.Heartbeat:Connect(function()
			local y = handle.Position.Y.Offset
			local clampedY = math.clamp(y, 0, TRACK_HEIGHT)
			if clampedY ~= y then
				handle.Position = UDim2.new(0.5, 0, 0, clampedY)
			end
			local v = 1 - (clampedY / TRACK_HEIGHT)
			if v ~= volume then
				setVolume(v)
			end
		end)
	end

	local function endDrag()
		draggingRef.current = false
		if hbConnRef.current then
			hbConnRef.current:Disconnect()
			hbConnRef.current = nil
		end
		-- Snap within bounds and ensure final volume is committed
		local handle = handleRef.current
		if handle then
			local y = math.clamp(handle.Position.Y.Offset, 0, TRACK_HEIGHT)
			handle.Position = UDim2.new(0.5, 0, 0, y)
			local v = 1 - (y / TRACK_HEIGHT)
			if v ~= volume then
				setVolume(v)
			end
		end
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Active = false,
	}, {
		SliderTrigger = e("TextButton", {
			Size = UDim2.new(0, 50, 0, 50),
			Position = UDim2.new(0, 0, 0.5, 0),
			Text = "🔊",
			ZIndex = 3,
			[React.Event.Activated] = toggleSlider,
		}, {
			rounded = e(rounded),
		}),

		SliderTrack = e("Frame", {
			Size = UDim2.new(0, 25, 0, TRACK_HEIGHT),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0, 25, 0.5, 0),
			ZIndex = 3,
			Visible = open,
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BackgroundTransparency = 0.2,
		}, {

			rounded = e(rounded),

			SliderHandle = e("Frame", {
				Size = UDim2.new(0, 50, 0, HANDLE_HEIGHT),
				AnchorPoint = Vector2.new(0.5, 0.5),
				-- initial position from volume; live updates are handled by drag or effect
				Position = UDim2.new(0.5, 0, 0, (1 - volume) * TRACK_HEIGHT),
				ZIndex = 4,
				BackgroundColor3 = Color3.fromRGB(200, 200, 200),
				ref = handleRef,
			}, {
				rounded = e(rounded),

				UIDragDetector = e("UIDragDetector", {
					DragAxis = Vector2.new(0, 1),
					DragStyle = Enum.UIDragDetectorDragStyle.TranslateLine,
					MaxDragTranslation = UDim2.new(0, 0, 0, TRACK_HEIGHT),
					MinDragTranslation = UDim2.new(0, 0, 0, 0),
					ref = detectorRef,

					[React.Event.DragStart] = beginDrag,
					[React.Event.DragEnd] = endDrag,
				}),
			}),
		}),
	})
end

return Slider
