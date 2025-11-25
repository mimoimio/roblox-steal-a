local React = require(game.ReplicatedStorage.Packages.React)
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local Players = game:GetService("Players")

local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type PlayerData = sharedtypes.PlayerData

local MoneyDisplayUpdate = game.ReplicatedStorage.Shared.Events:WaitForChild("MoneyDisplayUpdate")
local GetItemConfigs: RemoteFunction = game.ReplicatedStorage.Shared.Events:WaitForChild("GetItemConfigs")
local player = Players.LocalPlayer

local dialogues = {
	{
		Text = [[Welcome to Witch Tycoon! 🧙‍♀️ Step on the <font color="#0080FF" thickness="5">BLUE GLOWING</font> button to buy <font color="#0080FF" thickness="2">The Cauldron</font> generator!!!]],
	},
	{
		Text = [[Awesome! Now you need an <font color="#FFFF00" thickness="2">ITEM</font> to place in the generator. Press <font color="#FFD700" thickness="2">[G]</font> to open the <font color="#FFD700" thickness="2">SHOP</font>!]],
	},
	{
		Text = [[Great! Now buy a <font color="#FFFF00" thickness="2">Daybloom</font> from the shop to get started!]],
	},
	{
		Text = [[Perfect! Now close the shop and place your <font color="#FFFF00" thickness="2">Daybloom</font> in <font color="#0080FF" thickness="2">The Cauldron</font> slot!]],
	},
	{
		Text = [[Excellent! Now place the item in the slot. Hover over items to read their descriptions. Some items have <font color="#FF80FF" thickness="2">SPECIAL EFFECTS</font>!]],
	},
	{
		Text = [[Perfect! Wait a moment and collect your money by stepping on the <font color="#00FF40" thickness="2">GREEN GLOWING</font> button at your cash display!]],
	},
	{
		Text = [[Well done! Keep buying more generators to earn faster. Good luck! 🌟]],
	},
}

type TutoProps = {
	PlayerData: PlayerData,
	onFinish: (() -> ())?,
	activePanel: string?,
}

local getAnimatedText = require(script.Parent.Utils.getAnimatedText)

local function Tutorial(props: TutoProps)
	local step, setStep = useState(1)
	local previousMoney = useRef(props.PlayerData.Resources.Money)
	local cash, setCash = useState(props.PlayerData.Resources.Money)
	local wave, setWave = useState(0)
	local beamRef = useRef(nil)
	local itemConfigs, setItemConfigs = useState(nil)
	local character, setCharacter = useState(player.Character)

	-- Fix 1: Only animate when tutorial is visible
	useEffect(function()
		if step > 7 then
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
	end, { step }) -- Add dependency

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

	useEffect(function()
		local connection = MoneyDisplayUpdate.OnClientEvent:Connect(function(money, rate)
			setCash(money)
		end)
		setItemConfigs(GetItemConfigs:InvokeServer())
		return function()
			connection:Disconnect()
		end
	end, {})

	-- Beam effect for tutorial steps
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

		if not character or step > 7 then
			return
		end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end

		task.spawn(function()
			local targetPart = nil
			local rendererFolder = workspace:WaitForChild(player.Name .. "ItemRenderer", 5)

			if step == 1 then
				-- Beam to floor button (buy cauldron)
				targetPart = rendererFolder and rendererFolder:WaitForChild("Button_UID_642990dac88d3", 5)
				targetPart = targetPart
					and (targetPart.PrimaryPart or targetPart:FindFirstChildWhichIsA("BasePart", true))
			elseif step == 5 then
				-- Beam to Slot1 (place item)
				local itemSlots = rendererFolder and rendererFolder:FindFirstChild("ItemSlots")
				local slot1 = itemSlots and itemSlots:WaitForChild("Slot1", 5)
				targetPart = slot1 and slot1:FindFirstChild("SlotPart")
			elseif step == 6 then
				-- Beam to Collector button
				local GetPlayerCollector = game.ReplicatedStorage.Shared.Events:FindFirstChild("GetPlayerCollector")
				if GetPlayerCollector then
					targetPart = GetPlayerCollector:InvokeServer(player)
				end
			end

			if not targetPart then
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
			beam.Color = ColorSequence.new(Color3.fromRGB(255, 200, 100))
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
	end, { step, character })

	useEffect(function()
		local pd = props.PlayerData
		if not itemConfigs or not pd then
			return
		end

		-- Step 1: Check if bought cauldron
		if step == 1 and pd.OwnedItems[itemConfigs[1].ItemId] then
			setStep(2)
		end

		-- Step 2: Check if shop is open
		if step == 2 and props.activePanel == "shop" then
			setStep(3)
		end

		-- Step 3: Check if bought daybloom (has at least 1 item)
		if step == 3 then
			if pd.Items and #pd.Items > 0 then
				-- Check if shop is still open, stay on step 3
				if props.activePanel == "shop" then
					-- Still in shop, move to step 4 (close shop)
					setStep(4)
				end
			else
				-- No items yet, go back to step 2 if shop closed
				if props.activePanel ~= "shop" then
					setStep(2)
				end
			end
		end

		-- Step 4: Wait for shop to close
		if step == 4 and props.activePanel == "none" then
			setStep(5)
		end

		-- Step 5: Check if filled the cauldron slot (Slot1)
		if step == 5 and pd.ItemSlots["Slot1"] and pd.ItemSlots["Slot1"] ~= "none" then
			previousMoney.current = cash
			setStep(6)
		end

		-- Step 6: Check if collected money (money increased)
		if step == 6 and cash > previousMoney.current then
			setStep(7)
			-- Mark tutorial as finished
			task.delay(5, function()
				local Events = game.ReplicatedStorage.Shared.Events
				local FinishTutorial = Events:FindFirstChild("FinishTutorial")
				if FinishTutorial then
					FinishTutorial:FireServer()
				end
			end)
		end
	end, { props.PlayerData, cash, props.activePanel, step })

	-- Don't show tutorial if finished
	if step > 7 then
		return nil
	end

	local currentDialogue = dialogues[step]

	return React.createElement("TextLabel", {
		Text = "",
		Position = step < 5 and UDim2.new(0.5, 0, 1, 0) or UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = step < 5 and Vector2.new(0.5, 1) or Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BackgroundTransparency = 0.2,
		Size = UDim2.new(0.9, 0, 0, 120),
		BorderSizePixel = 0,
		Active = false,
	}, {
		rounded = React.createElement(require(script.Parent.ui.rounded)),
		padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
			PaddingTop = UDim.new(0, 15),
			PaddingBottom = UDim.new(0, 15),
		}),
		ImageLabel = React.createElement("ImageLabel", {
			Size = UDim2.new(1.5, 0, 1.5, 0), -- 1:1 aspect ratio
			Position = step < 5 and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 0, 1, 0), -- left side, above text
			AnchorPoint = step < 5 and Vector2.new(0, 1) or Vector2.new(0, 0),
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
				Size = UDim2.new(1, 0, 1, 0), -- 1:1 aspect ratio
				Position = UDim2.new(0, 0, 0, 0), -- left side, above text
				BackgroundTransparency = 1,
				Image = "rbxassetid://100717443703038", -- Replace with your image asset id
			}),
		}),
		TextLabel = React.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			TextSize = 18,
			TextStrokeTransparency = 0,
			Active = false,
			Text = getAnimatedText(currentDialogue.Text, wave),
			TextColor3 = Color3.new(1, 1, 1),
			TextWrapped = true,
			RichText = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
		}),
	})
end

return Tutorial
