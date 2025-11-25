local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type PlayerData = sharedtypes.PlayerData
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useEffect = React.useEffect
local rf = game.ReplicatedStorage.Shared.Events:WaitForChild("GetPlayerSettings")

local OPEN_SOUND = Instance.new("Sound", game.Players.LocalPlayer)
OPEN_SOUND.SoundId = "rbxassetid://9117231552"

local TS = game:GetService("TweenService")

local OPEN_SIZE = UDim2.new(1, 0, 1, 0)
local OPEN_POS = UDim2.new(0.5, 0, 0.5, 0)
local CLOSED_SIZE = UDim2.new(0, 0, 0, 0)
local CLOSED_POS = UDim2.new(1.5, 0, 1.5, 0)

local function Music(props: { PlayerData: PlayerData })
	local Phase: "opening" | "open" | "closing" | "closed", setPhase = React.useState("closed")
	local visible, setVisible = React.useState(Phase ~= "closed")

	local musics, setMusics = React.useState({} :: { Sound })
	local currentIndex, setCurrentIndex = React.useState(1)

	local playingSoundRef = React.useRef(nil)
	local endedConnRef = React.useRef(nil)

	local PlayerData: PlayerData? = props.PlayerData or {}
	local PlayerSettings = PlayerData.PlayerSettings or {}

	local Volume, setVolume = React.useState(PlayerSettings.MusicVolume or 1)
	local playingBaseVolumeRef = React.useRef(1) -- stores the cloned sound's original Volume
	local settingsLoaded, setSettingsLoaded = React.useState(false)

	local animDur = 0.4
	local FrameRef = React.useRef()
	local tweenRef = React.useRef(nil)

	-- initialize musics
	useEffect(function()
		local folder = game.ReplicatedStorage.Shared:FindFirstChild("Music")
		local list = {}
		if folder then
			for _, inst in folder:GetDescendants() do
				if inst:IsA("Sound") then
					table.insert(list, inst)
					-- warn(inst)
				end
			end
		else
			warn("NO MUSIc")
		end
		if #list == 0 then
			list = { OPEN_SOUND }
		end
		setMusics(list)
	end, {})

	-- fetch player settings and set initial volume; render nothing until this completes
	useEffect(function()
		local ok, settings = pcall(function()
			if rf and rf:IsA("RemoteFunction") then
				return rf:InvokeServer()
			end
			return nil
		end)
		if ok and type(settings) == "table" then
			local vol = settings.MusicVolume
			if type(vol) ~= "number" then
				vol = 1
			end
			vol = math.clamp(vol, 0, 1)
			if settings.MusicMuted == true then
				vol = 0
			end
			setVolume(vol)
		end
		setSettingsLoaded(true)
	end, {})

	-- start loop
	useEffect(function()
		if musics and #musics > 0 then
			setCurrentIndex(1)
		end
	end, { musics })

	-- Play current track when currentIndex changes
	useEffect(function()
		-- Cleanup previous sound and connection
		if playingSoundRef.current then
			playingSoundRef.current:Destroy()
			playingSoundRef.current = nil
		end
		if endedConnRef.current then
			endedConnRef.current:Disconnect()
			endedConnRef.current = nil
		end

		if musics and musics[currentIndex] then
			local sound = musics[currentIndex]:Clone()
			sound.Parent = game.Players.LocalPlayer

			-- apply volume multiplier (0..1) against the sound's original Volume
			local baseVol = math.clamp(sound.Volume or 1, 0, 10)
			playingBaseVolumeRef.current = baseVol
			sound.Volume = math.clamp(baseVol * Volume, 0, 10)

			playingSoundRef.current = sound
			sound:Play()
			endedConnRef.current = sound.Ended:Connect(function()
				local nextIndex = currentIndex + 1
				if nextIndex > #musics then
					nextIndex = 1
				end
				setCurrentIndex(nextIndex)
			end)
		end

		-- Cleanup on unmount
		return function()
			if playingSoundRef.current then
				playingSoundRef.current:Destroy()
				playingSoundRef.current = nil
			end
			if endedConnRef.current then
				endedConnRef.current:Disconnect()
				endedConnRef.current = nil
			end
		end
	end, { currentIndex, musics })

	-- Re-apply volume whenever Volume state changes
	useEffect(function()
		local s = playingSoundRef.current
		if s then
			local base = playingBaseVolumeRef.current or 1
			s.Volume = math.clamp(base * Volume, 0, 10)
		end
	end, { Volume })

	-- open ui
	useEffect(function()
		local sound = OPEN_SOUND:Clone()
		sound.Parent = game.Players.LocalPlayer
		local c = sound.IsLoaded or sound.Loaded:Wait()

		local frame = FrameRef.current
		if not frame then
			return
		end

		-- Cancel previous tween if any
		if tweenRef.current then
			tweenRef.current:Cancel()
			tweenRef.current = nil
		end
		local connections = {}
		if props.MusicOpen then
			setPhase("opening")
			setVisible(true) -- show immediately
			local tween = TS:Create(
				frame,
				TweenInfo.new(animDur, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
				{ Size = OPEN_SIZE, Position = OPEN_POS }
			)
			tweenRef.current = tween
			connections["nah"] = tween.Completed:Connect(function(playbackState)
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
			game.ReplicatedStorage.Shared.Events.SetPlayerSettings:FireServer({ MusicVolume = Volume })
			local tween = TS:Create(frame, TweenInfo.new(animDur), { Size = CLOSED_SIZE, Position = CLOSED_POS })
			tweenRef.current = tween
			connections["yeah"] = tween.Completed:Connect(function(playbackState)
				if playbackState == Enum.PlaybackState.Completed then
					setPhase("closed")
					setVisible(false) -- hide after close finishes
				end
			end)
			tween:Play()
		end
		return function()
			for i, conn in connections do
				conn:Disconnect()
			end
		end
	end, { props.MusicOpen })

	-- handle prev and next operations
	local handlePrevButton = function()
		if musics and #musics > 0 then
			local prev = currentIndex - 1
			if prev < 1 then
				prev = #musics
			end
			setCurrentIndex(prev)
		end
	end

	local handleNextButton = function()
		if musics and #musics > 0 then
			local next = currentIndex + 1
			if next > #musics then
				next = 1
			end
			setCurrentIndex(next)
		end
	end

	if not settingsLoaded then
		return nil -- wait for settings before showing anything
	end

	return e("Frame", {
		Size = CLOSED_SIZE,
		Position = CLOSED_POS,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(0, 0.2, 0.2),
		BackgroundTransparency = 0.2,
		Active = false,
		Visible = visible,
		ref = FrameRef,
	}, {
		MainLayout = e("Frame", {
			Size = OPEN_SIZE,
			Position = OPEN_POS,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Active = false,
		}, {
			Label = e("TextLabel", {
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.new(0, 0.2, 0.2),
				Text = "Now Playing:",
				TextSize = 24,
				TextColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 1,
				Font = "FredokaOne",
				LayoutOrder = 0,
			}),
			NowPlayingFrame = e("Frame", {
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.new(0, 0.2, 0.2),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				e("TextLabel", {
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.new(0, 0.2, 0.2),
					Text = musics[currentIndex] and musics[currentIndex].Name or "None",
					TextSize = 48,
					TextWrapped = true,
					TextColor3 = Color3.new(1, 1, 1),
					Font = "FredokaOne",
					BackgroundTransparency = 1,
					LayoutOrder = 1,
				}),
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 16),
				}),
			}),
			Buttons = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundColor3 = Color3.new(0, 0.2, 0.2),
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				Active = true,
				Visible = visible,
				LayoutOrder = 2,
			}, {
				Prev = e("TextButton", {
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.new(0.427450, 0.341176, 0.074509),
					Text = "Prev",
					TextSize = 48,
					TextColor3 = Color3.new(1, 1, 1),
					Font = "FredokaOne",
					BackgroundTransparency = 0.6,
					LayoutOrder = 1,
					[React.Event.Activated] = handlePrevButton,
				}, { pad = e(require(script.Parent.ui.padding)), cor = e(require(script.Parent.ui.rounded)) }),
				Next = e("TextButton", {
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.new(0.972549, 0.447058, 0.070588),
					Text = "Next",
					TextSize = 48,
					TextColor3 = Color3.new(1, 1, 1),
					Font = "FredokaOne",
					BackgroundTransparency = 0.6,
					LayoutOrder = 2,
					[React.Event.Activated] = handleNextButton,
				}, { pad = e(require(script.Parent.ui.padding)), cor = e(require(script.Parent.ui.rounded)) }),
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 16),
				}),
			}),
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 16),
			}),
		}),
		Slider = e(require(script.Slider), {
			initialVolume = Volume,
			onVolumeChange = function(v: number)
				-- clamp 0..1 then set
				setVolume(math.clamp(v, 0, 1))
			end,
		}),
		CloseButton = e("TextButton", {
			-- AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(0, 42, 0, 42),
			BorderSizePixel = 0,
			Text = "X",
			Font = "FredokaOne",
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.new(1, 0.2, 0.4),
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 42,
			ZIndex = 2,
			[React.Event.Activated] = props.close,
			Position = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(1, 0),
		}, {
			Rounded = e(require(script.Parent.ui.rounded)),
		}),
		Padding = React.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
		}, {}),
	})
end

return Music
