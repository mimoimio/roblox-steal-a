local React = require(game.ReplicatedStorage.Packages.React)
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local Players = game:GetService("Players")

local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type PlayerData = sharedtypes.PlayerData

local player = Players.LocalPlayer

local dialogues = {
	{
		Text = [[Here's a broom! 🧹 Use the <font color="#00FF88">Proximity Prompt</font> to take it from the stand.]],
	},
	{
		Text = [[Great! Now <font color="#FFFF00">equip</font> the broomstick from your inventory/hotbar to start flying!]],
	},
	{
		Text = [[Perfect! Control <font color="#FF8888">horizontal</font> movement with your character, and <font color="#88FF88">vertical</font> movement by looking up or down with your camera! ⬆️⬇️]],
	},
	{
		Text = [[Well done! Have fun! ✨]],
	},
}

type BroomstickTutoProps = {
	PlayerData: PlayerData,
	onFinish: (() -> ())?,
}

local getAnimatedText = require(script.Parent.Utils.getAnimatedText)

local function BroomstickTutorial(props: BroomstickTutoProps)
	local step, setStep = useState(1)
	local wave, setWave = useState(0)
	local character, setCharacter = useState(player.Character)
	local equippedTimeRef = useRef(nil)
	local beamRef = useRef(nil)

	-- Check if player owns broomstick1 and hasn't completed broom tutorial
	local shouldShow = props.PlayerData.OwnedItems
		and props.PlayerData.OwnedItems["UID_643290bfd4db6"]
		and not props.PlayerData.BroomTutorialFinished

	-- Animate wave
	useEffect(function()
		if not shouldShow or step > 4 then
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
	end, { shouldShow, step })

	-- Track character changes
	useEffect(function()
		setCharacter(player.Character)

		local charAddedConn = player.CharacterAdded:Connect(function(newChar)
			setCharacter(newChar)
		end)

		local charRemovingConn = player.CharacterRemoving:Connect(function()
			setCharacter(nil)
			-- Clean up beam when character is removed
			if beamRef.current then
				if beamRef.current.beam then
					beamRef.current.beam:Destroy()
				end
				if beamRef.current.att0 then
					beamRef.current.att0:Destroy()
				end
				if beamRef.current.att1 then
					beamRef.current.att1:Destroy()
				end
				if beamRef.current.arrowGui then
					beamRef.current.arrowGui:Destroy()
				end
				beamRef.current = nil
			end
		end)

		return function()
			charAddedConn:Disconnect()
			charRemovingConn:Disconnect()
		end
	end, {})

	-- Beam effect for step 1 (point to broomstick model)
	useEffect(function()
		-- Cleanup old beam
		if beamRef.current then
			if beamRef.current.beam then
				beamRef.current.beam:Destroy()
			end
			if beamRef.current.att1 then
				beamRef.current.att1:Destroy()
			end
			if beamRef.current.arrowGui then
				beamRef.current.arrowGui:Destroy()
			end
		end

		-- Only show beam on step 1
		if not shouldShow or step ~= 1 or not character then
			return
		end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end

		task.spawn(function()
			-- Find the broomstick model in workspace by UID
			local broomstickUID = "UID_643290bfd4db6"
			local broomstickModel = workspace:FindFirstChild(broomstickUID)

			if not broomstickModel then
				warn("[BroomstickTutorial] Broomstick model not found:", broomstickUID)
				return
			end

			local targetPart = broomstickModel.PrimaryPart or broomstickModel:FindFirstChildWhichIsA("BasePart", true)

			if not targetPart then
				warn("[BroomstickTutorial] No valid part found in broomstick model")
				return
			end

			-- Create/reuse attachments
			local att0 = beamRef.current and beamRef.current.att0
			if not att0 or not att0.Parent then
				att0 = Instance.new("Attachment")
				att0.Parent = hrp
			end

			local att1 = Instance.new("Attachment")
			att1.Parent = targetPart

			-- Create beam
			local beam = Instance.new("Beam")
			beam.Attachment0 = att0
			beam.Attachment1 = att1
			beam.Width0 = 0.5
			beam.Width1 = 0.5
			beam.Color = ColorSequence.new(Color3.fromRGB(100, 255, 200)) -- Greenish color for broomstick
			beam.FaceCamera = true
			beam.Texture = "rbxassetid://136242854116857"
			beam.TextureSpeed = 0.3
			beam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(0.5, 0.1),
				NumberSequenceKeypoint.new(1, 0.3),
			})
			beam.Parent = hrp

			-- Add arrow GUI
			local arrowGui
			local arrowTemplate = game.ReplicatedStorage.Shared:FindFirstChild("ArrowGui")
			if arrowTemplate then
				arrowGui = arrowTemplate:Clone()
				arrowGui.Parent = att1
				arrowGui.Enabled = true
			end

			beamRef.current = {
				beam = beam,
				att0 = att0,
				att1 = att1,
				arrowGui = arrowGui,
			}
		end)

		return function()
			if beamRef.current then
				if beamRef.current.beam then
					beamRef.current.beam:Destroy()
				end
				if beamRef.current.att1 then
					beamRef.current.att1:Destroy()
				end
				if beamRef.current.arrowGui then
					beamRef.current.arrowGui:Destroy()
				end
				-- Keep att0 for reuse
			end
		end
	end, { shouldShow, step, character })

	-- Tutorial progression logic
	useEffect(function()
		if not shouldShow then
			return
		end
		props.setSHOWBEAM(false)
		-- Step 1: Check if player has broomstick1 in backpack
		if step == 1 then
			local backpack = player:WaitForChild("Backpack")
			local hasBroomInBackpack = backpack:FindFirstChild("broomstick1")

			if hasBroomInBackpack then
				setStep(2)
			else
				-- Listen for child added to backpack
				local connection
				connection = backpack.ChildAdded:Connect(function(child)
					if child.Name == "broomstick1" then
						setStep(2)
						if connection then
							connection:Disconnect()
						end
					end
				end)

				return function()
					if connection then
						connection:Disconnect()
					end
				end
			end
		end

		-- Step 2: Check if broomstick1 is equipped (in character)
		if step == 2 and character then
			local isBroomEquipped = character:FindFirstChild("broomstick1")
			if isBroomEquipped then
				equippedTimeRef.current = tick()
				setStep(3)
			else
				-- Listen for child added to character
				local connection
				connection = character.ChildAdded:Connect(function(child)
					if child.Name == "broomstick1" then
						equippedTimeRef.current = tick()
						setStep(3)
						if connection then
							connection:Disconnect()
						end
					end
				end)

				return function()
					if connection then
						connection:Disconnect()
					end
				end
			end
		end

		-- Step 3: Wait 5 seconds after equipping
		if step == 3 and equippedTimeRef.current then
			local elapsed = tick() - equippedTimeRef.current
			if elapsed >= 5 then
				setStep(4)
			else
				local thread = task.spawn(function()
					task.wait(5 - elapsed)
					setStep(4)
				end)
				return function()
					task.cancel(thread)
				end
			end
		end

		-- Step 4: Mark tutorial as finished after 8 seconds
		if step == 4 then
			local thread = task.spawn(function()
				task.wait(4)
				local Events = game.ReplicatedStorage.Shared.Events
				local FinishBroomTutorial = Events:FindFirstChild("FinishBroomTutorial")
				if FinishBroomTutorial then
					FinishBroomTutorial:FireServer()
				end
				props.setSHOWBEAM(true)
			end)
			return function()
				task.cancel(thread)
			end
		end
	end, { shouldShow, step, character, props.PlayerData })

	-- Don't show if conditions not met or finished
	if not shouldShow or step > 4 then
		return nil
	end

	local currentDialogue = dialogues[step]

	return React.createElement("ImageButton", {
		Position = UDim2.new(0.5, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(40, 40, 60),
		BackgroundTransparency = 0.2,
		Size = UDim2.new(0.9, 0, 0, 120),
		BorderSizePixel = 0,
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
			ImageLabel = React.createElement("ImageLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				Image = "rbxassetid://100717443703038", -- Replace with broomstick icon
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
	})
end

return BroomstickTutorial
