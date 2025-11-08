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
		Text = [[Welcome to Witch Tycoon! 🧙‍♀️ Step on the glowing button to buy the Floor!]],
	},
	{
		Text = [[Great! Now you need a 'Generator' to make money. Buy the 'Cauldron' generator!]],
	},
	{
		Text = [[Awesome! Now place an item in the Cauldron slot to start earning!]],
	},
	{
		Text = [[Perfect! Wait a moment and collect your money by clicking on your money display!]],
	},
	{
		Text = [[Well done! Keep buying more generators to earn faster. Good luck! 🌟]],
	},
}

type TutoProps = {
	PlayerData: PlayerData,
	onFinish: (() -> ())?,
}

local function getAnimatedText(text, currentWave)
	local richText = ""
	local index = 0

	-- utf8.graphemes is used to correctly handle multi-byte characters like emojis
	for first, last in utf8.graphemes(text) do
		local char = text:sub(first, last)
		-- Escape special XML characters to prevent them from breaking RichText
		if char == "<" then
			char = "&lt;"
		elseif char == ">" then
			char = "&gt;"
		elseif char == "&" then
			char = "&amp;"
		end
		local size = 18 + ((index + currentWave) % 5)
		richText = richText .. string.format('<font size="%d">%s</font>', size, char)
		index += 1
	end
	return richText
end

local function Tutorial(props: TutoProps)
	local step, setStep = useState(1)
	local previousMoney = useRef(props.PlayerData.Resources.Money)
	local cash, setCash = useState(props.PlayerData.Resources.Money)
	local wave, setWave = useState(0)

	useEffect(function()
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
	end, {})

	useEffect(function()
		local MoneyDisplayUpdate: UnreliableRemoteEvent =
			game.ReplicatedStorage.Shared.Events:WaitForChild("MoneyDisplayUpdate")
		MoneyDisplayUpdate = MoneyDisplayUpdate.OnClientEvent:Connect(function(money, rate)
			setCash(money)
		end)
	end, {})

	useEffect(function()
		local pd = game.ReplicatedStorage.Shared.Events:WaitForChild("GetPlayerData"):InvokeServer()
		-- warn("Step", step)
		-- Step 1: Check if bought the floor
		-- warn(pd.OwnedItems)
		if step == 1 and pd.OwnedItems["floor"] then
			setStep(2)
		end

		-- Step 2: Check if bought the cauldron
		if step == 2 and pd.OwnedItems["UID_642990dac88d3"] then
			setStep(3)
		end

		-- Step 3: Check if filled the cauldron slot (Slot1)
		if step == 3 and pd.ItemSlots["Slot1"] and pd.ItemSlots["Slot1"] ~= "none" then
			previousMoney.current = pd.Resources.Money
			setStep(4)
		end

		-- Step 4: Check if collected money (money increased)
		if step == 4 and pd.Resources.Money > previousMoney.current then
			setStep(5)
			-- Mark tutorial as finished
			-- TODO: Fire RemoteEvent to save TutorialFinished = true on server
			task.delay(5, function()
				-- Notify parent that tutorial finished (so parent can refresh PlayerData)
				local Events = game.ReplicatedStorage.Shared.Events
				local FinishTutorial = Events:FindFirstChild("FinishTutorial")
				if FinishTutorial then
					-- warn("Fire")
					FinishTutorial:FireServer()
				end
			end)
		end

		-- Step 5: Tutorial complete, hide after a few seconds
		if step == 5 then
		end
	end, { props.PlayerData, cash })

	-- Don't show tutorial if finished
	if step > 5 then
		return nil
	end

	local currentDialogue = dialogues[step]

	return React.createElement("ImageButton", {
		Position = UDim2.new(0.5, 0, 1, 0),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
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
			Size = UDim2.new(0, 200, 0, 200), -- 1:1 aspect ratio
			Position = UDim2.new(0, 0, 0, 0), -- left side, above text
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
			Image = "rbxassetid://136242854116857",
			ScaleType = Enum.ScaleType.Slice,
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
