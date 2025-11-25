local React = require(game.ReplicatedStorage.Packages.React)
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef

-- Hardcoded NPC dialogues by NPC ID
local npcDialogues = {
	["Mitch"] = {
		{
			Text = [[Hello! ✨]],
			Duration = 3,
		},
		{
			Text = [[Shut up! ✨]],
			Duration = 3,
		},
		{
			Text = [[Look at me dancing! ✨]],
			Duration = 3,
		},
		{
			Text = [[UwU]],
			Duration = 3,
		},
	},
}

local getAnimatedText = require(script.Parent.Utils.getAnimatedText)

local function NpcDialogue(props)
	local visible, setVisible = useState(false)
	local currentNpcId, setCurrentNpcId = useState(nil)
	local dialogueIndex, setDialogueIndex = useState(1)
	local wave, setWave = useState(0)
	local autoProgressTimerRef = useRef(nil)

	-- Animation wave effect
	useEffect(function()
		if not visible then
			return
		end

		local thread = task.spawn(function()
			while true do
				task.wait(0.1)
				setWave(function(prevWave)
					return prevWave + 1
				end)
			end
		end)
		return function()
			task.cancel(thread)
		end
	end, { visible })

	-- Listen for NPC dialogue trigger events
	useEffect(function()
		local Events = game.ReplicatedStorage.Shared.Events
		local ShowNpcDialogue = Events:WaitForChild("ShowNpcDialogue")

		local connection = ShowNpcDialogue.OnClientEvent:Connect(function(npcId)
			if npcDialogues[npcId] then
				setCurrentNpcId(npcId)
				setDialogueIndex(1)
				setVisible(true)
			else
				warn("No dialogue found for NPC:", npcId)
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	-- Auto-progress dialogue based on duration
	useEffect(function()
		if not visible or not currentNpcId then
			return
		end

		local dialogues = npcDialogues[currentNpcId]
		if not dialogues then
			return
		end

		local currentDialogue = dialogues[dialogueIndex]
		if not currentDialogue then
			return
		end

		-- Clear previous timer
		if autoProgressTimerRef.current then
			task.cancel(autoProgressTimerRef.current)
		end

		-- Set new timer for auto-progress
		autoProgressTimerRef.current = task.delay(currentDialogue.Duration or 5, function()
			if dialogueIndex < #dialogues then
				setDialogueIndex(dialogueIndex + 1)
			else
				-- End of dialogue sequence
				setVisible(false)
				setCurrentNpcId(nil)
				setDialogueIndex(1)
			end
		end)

		return function()
			if autoProgressTimerRef.current then
				task.cancel(autoProgressTimerRef.current)
			end
		end
	end, { visible, currentNpcId, dialogueIndex })

	-- Don't render if not visible
	if not visible or not currentNpcId then
		return nil
	end

	local dialogues = npcDialogues[currentNpcId]
	if not dialogues then
		return nil
	end

	local currentDialogue = dialogues[dialogueIndex]
	if not currentDialogue then
		return nil
	end

	return React.createElement("ImageButton", {
		Position = UDim2.new(0.5, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BackgroundTransparency = 0.2,
		Size = UDim2.new(0.9, 0, 0, 120),
		BorderSizePixel = 0,
		[React.Event.Activated] = function()
			-- Click to progress or skip
			if dialogueIndex < #dialogues then
				setDialogueIndex(dialogueIndex + 1)
			else
				setVisible(false)
				setCurrentNpcId(nil)
				setDialogueIndex(1)
			end
		end,
	}, {
		rounded = React.createElement(require(script.Parent.ui.rounded)),
		padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
			PaddingTop = UDim.new(0, 15),
			PaddingBottom = UDim.new(0, 15),
		}),
		ImageLabel = React.createElement("ImageLabel", {
			Size = UDim2.new(1.5, 0, 1.5, 0),
			Position = UDim2.new(0, 0, 0, 0),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
			Image = "rbxassetid://136242854116857",
			ScaleType = Enum.ScaleType.Slice,
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			SliceCenter = Rect.new(30, 30, 90, 90),
		}, {
			padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				PaddingTop = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
			}),
			-- NPC portrait/icon
			ImageLabel = React.createElement("ImageLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				Image = "rbxassetid://100717443703038", -- Replace with NPC-specific portraits
			}),
		}),
		TextLabel = React.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			TextSize = 18,
			Text = getAnimatedText(currentDialogue.Text, wave),
			TextColor3 = Color3.new(1, 1, 1),
			TextWrapped = true,
			RichText = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
		}),
		ProgressIndicator = React.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 1, 0),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			TextSize = 12,
			Text = string.format("%d/%d - Click to continue", dialogueIndex, #dialogues),
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextXAlignment = Enum.TextXAlignment.Center,
		}),
	})
end

return NpcDialogue
