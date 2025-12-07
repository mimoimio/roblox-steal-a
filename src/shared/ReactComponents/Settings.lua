local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type PlayerData = sharedtypes.PlayerData

local React = require(game.ReplicatedStorage.Packages.React)
local TS = game:GetService("TweenService")

local OPEN_POS = UDim2.new(0.5, 0, 0.5, 0)
local CLOSED_POS = UDim2.new(0.5, 0, -0.5, 0)

local Events = game.ReplicatedStorage.Shared.Events
local GetTotalItemCount: RemoteFunction = Events:WaitForChild("GetTotalItemCount")
local GetOwnedItems: RemoteFunction = Events:WaitForChild("GetOwnedItems")
local OwnedItemsUpdated: RemoteEvent = Events:WaitForChild("OwnedItemsUpdated", 5)

local function Settings(props: {
	SettingsOpen: boolean,
	PlayerData: PlayerData,
})
	local Phase: "opening" | "open" | "closing" | "closed", setPhase = React.useState("closed")
	local visible, setVisible = React.useState(Phase ~= "closed")
	local ownedItems, setOwnedItems = React.useState({})
	local totalItemCount, setTotalItemCount = React.useState(0)

	local animDur = 0.4
	local FrameRef = React.useRef()
	local tweenRef = React.useRef(nil)

	-- Fetch total item count from server
	-- Fetch total item count and owned items from server, and listen for updates
	React.useEffect(function()
		-- Get total item count
		local count = GetTotalItemCount:InvokeServer()
		setTotalItemCount(count)

		-- Get owned items
		local owned = GetOwnedItems:InvokeServer()
		if owned and type(owned) == "table" then
			setOwnedItems(owned)
		end

		-- Listen for updates to owned items
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

	-- Calculate owned items count
	local ownedCount = 0
	if ownedItems then
		for _ in ownedItems do
			ownedCount = ownedCount + 1
		end
	end

	-- Calculate progress (0 to 1)
	local progress = totalItemCount > 0 and (ownedCount / totalItemCount) or 0

	return React.createElement("Frame", {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 400, 0, 300),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = visible,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ref = FrameRef,
	}, {

		RebirthButton = React.createElement("TextButton", {
			Size = UDim2.new(0, 100, 0, 50),
			Position = UDim2.new(0, 110, 0, 0),
			Text = "Rebirth (+5%)",
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

		ProgressContainer = React.createElement("Frame", {
			Size = UDim2.new(0, 350, 0, 80),
			Position = UDim2.new(0.5, 0, 0, 70),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
		}, {
			Title = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				Text = "Collection Progress",
				Font = "FredokaOne",
				TextSize = 16,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Center,
			}),

			ProgressBarBackground = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 30),
				Position = UDim2.new(0, 0, 0, 25),
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				BorderSizePixel = 0,
			}, {
				ProgressBar = React.createElement("Frame", {
					Size = UDim2.new(progress, 0, 1, 0),
					BackgroundColor3 = Color3.fromRGB(100, 200, 100),
					BorderSizePixel = 0,
				}),
				rounded = React.createElement(require(script.Parent.ui.rounded)),
			}),

			ProgressText = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				Position = UDim2.new(0, 0, 0, 60),
				BackgroundTransparency = 1,
				Text = string.format("(%.2f%%)", progress * 100),
				Font = "FredokaOne",
				TextSize = 14,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Center,
			}),
		}),

		padding = React.createElement(require(script.Parent.ui.padding)),
		rounded = React.createElement(require(script.Parent.ui.rounded)),
	})
end

return Settings
