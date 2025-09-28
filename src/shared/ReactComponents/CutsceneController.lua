local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local React = require(game.ReplicatedStorage.Packages.React)
local ContextActionService = game:GetService("ContextActionService")
local FREEZE_ACTION = "freezeMovement"

export type CutsceneControllerProps = {
	OnCutsceneStart: (() -> ())?,
	OnCutsceneEnd: (() -> ())?,
	Duration: number?, -- hold time at focus
	TweenTime: number?, -- time to move in/out
	Distance: number?, -- distance from target
	HeightOffset: number?,
	HideTweenTime: number?,
	ShowTweenTime: number?,
}

--[[

	How should interactions with shop npcs be like?

		prompt triggered
		|
		v
		greetings
		|
		v
		open up shop gui
		|
		v
		player do operations
		|
		v
		player exit
		|
		v
		goodbyes
		|
		v
		close shop gui

	Wandering trader may sell Rare stuffs for a stuff of your own.
		A Lightning Ball in a jar.
		Place Item for npc to decide the worth.
		conditions: {minimum rate?, rarity? variation?}
			- deterministic cost: a conditions always the same.
			- probabilistic cost: randomly set conditions.

	A witch may sell buffs with side effects:
		increment all placed items' by 1
		increment all placed items' by 10
		increment a random item rate by 10
		a witch's own item

]]

local function CutsceneController(props: CutsceneControllerProps)
	local playingRef = React.useRef(false)
	local camStartCFrameRef = React.useRef(nil :: CFrame?)
	local dialogueIndex, setDialogueIndex = React.useState(1)
	local visible, setVisible = React.useState(false)
	local dialogues, setDialogues = React.useState({
		"...The air feels different here...",
		"A faint hum echoes in the distance...",
		"Something ancient is awakening...",
		"Hello!",
		"See ya!",
	})

	local duration = props.Duration or 4
	local tweenTime = props.TweenTime or 0.5
	local distance = props.Distance or 8
	local heightOffset = props.HeightOffset or 0
	local hideTweenTime = props.HideTweenTime or 0.25
	local showTweenTime = props.ShowTweenTime or 0.25

	local function playCutscene(prompt: ProximityPrompt)
		setDialogues(require(game.ReplicatedStorage.Shared.Configs.ShopsConfig[prompt.Name]).Dialogues)
		warn(prompt)
		if playingRef.current then
			return
		end

		playingRef.current = true
		if props.OnCutsceneStart then
			pcall(props.OnCutsceneStart)
		end

		ContextActionService:BindAction(FREEZE_ACTION, function()
			return Enum.ContextActionResult.Sink
		end, false, unpack(Enum.PlayerActions:GetEnumItems()))

		local part = prompt.Parent :: PVInstance
		-- if not part or not part:IsA("BasePart") then
		-- 	playingRef.current = false
		-- 	return
		-- end
		prompt.Enabled = false
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Scriptable
		camStartCFrameRef.current = cam.CFrame

		-- Hide local character (BaseParts & Decals) and remember originals
		local restoreList = {}
		local lp = game.Players.LocalPlayer
		local character = lp and (lp.Character or lp.CharacterAdded:Wait())
		if character then
			for _, inst in ipairs(character:GetDescendants()) do
				if inst:IsA("BasePart") then
					local bp = inst :: BasePart
					local orig = bp.Transparency
					if orig < 1 then
						table.insert(restoreList, { inst = bp, prop = "Transparency", value = orig })
						TweenService:Create(
							bp,
							TweenInfo.new(hideTweenTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
							{ Transparency = 1 }
						):Play()
					end
				elseif inst:IsA("Decal") then
					local decal = inst :: Decal
					local orig = decal.Transparency
					if orig < 1 then
						table.insert(restoreList, { inst = decal, prop = "Transparency", value = orig })
						TweenService:Create(
							decal,
							TweenInfo.new(hideTweenTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
							{ Transparency = 1 }
						):Play()
					end
				end
			end
		end

		-- Choose direction from current camera to part to keep continuity
		local currentPos = cam.CFrame.Position
		local dir = (currentPos - part:GetPivot().Position).Magnitude > 0
				and (currentPos - part:GetPivot().Position).Unit
			or part:GetPivot().LookVector
		local targetPos = part:GetPivot():ToWorldSpace(CFrame.new(0, 0, -5)).Position
		-- local targetPos = part:GetPivot().Position + dir * distance + Vector3.new(0, heightOffset, 0)
		local targetCFrame = CFrame.new(targetPos, part:GetPivot().Position)
		local inTween =
			TweenService:Create(cam, TweenInfo.new(tweenTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				CFrame = targetCFrame,
			})
		inTween:Play()
		inTween.Completed:Wait()

		-- Show dialogue UI
		setDialogueIndex(1)
		setVisible(true)
		-- Cycle placeholder lines while holding
		task.spawn(function()
			local i = 1
			local startTime = tick()
			while playingRef.current and tick() - startTime < duration do
				setDialogueIndex(i)
				i = i % #dialogues + 1
				for _ = 1, 10 do
					if not playingRef.current then
						break
					end
					task.wait(0.1)
				end
			end
		end)

		task.wait(duration)

		-- Restore character visuals
		for _, info in ipairs(restoreList) do
			local inst = info.inst
			if inst and inst.Parent then
				pcall(function()
					local anim: Tween = TweenService:Create(
						inst,
						TweenInfo.new(showTweenTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{ Transparency = info.value }
					):Play()
					-- anim.Completed:Wait()
					-- return nil
				end)
			end
		end

		local startCFrame = camStartCFrameRef.current
		if startCFrame then
			local outTween =
				TweenService:Create(cam, TweenInfo.new(tweenTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					CFrame = startCFrame,
				})
			outTween:Play()
			outTween.Completed:Wait()
		end
		cam.CameraType = Enum.CameraType.Custom
		prompt.Enabled = true
		setVisible(false)
		playingRef.current = false

		if props.OnCutsceneEnd then
			pcall(props.OnCutsceneEnd)
		end

		--to unfreeze

		ContextActionService:UnbindAction(FREEZE_ACTION)
	end

	React.useEffect(function()
		local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
			if
				player == game.Players.LocalPlayer
				and game.ReplicatedStorage.Shared.Configs.ShopsConfig:FindFirstChild(prompt.Name)
			then
				playCutscene(prompt)
			end
		end
		local conn = ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
		return function()
			conn:Disconnect()
		end
	end, {})

	return React.createElement("Frame", {
		Name = "CutsceneUI",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = visible,
		ZIndex = 999,
	}, {
		DialogueFrame = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -40),
			Size = UDim2.new(0.6, 0, 0, 120),
			BackgroundColor3 = Color3.fromRGB(20, 20, 25),
			BackgroundTransparency = 0.2,
			Visible = visible,
			ZIndex = 1000,
		}, {
			UICorner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
			UITextSizeConstraint = React.createElement("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 32 }),
			Padding = React.createElement("UIPadding", {
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
			}),
			DialogueLabel = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				RichText = true,
				Font = Enum.Font.FredokaOne,
				TextColor3 = Color3.new(1, 1, 1),
				TextStrokeTransparency = 0.5,
				Text = dialogues[dialogueIndex] or "...",
				TextSize = 32,
				ZIndex = 1001,
			}),
		}),
	})
end

return CutsceneController
