--[[
	Client-side component that creates a beam from the player to the next unlocked button
	Renders a toggle button in the HUD to enable/disable the beam
]]

local React = require(game.ReplicatedStorage.Packages.React)
local Players = game:GetService("Players")

local player = Players.LocalPlayer

type ItemConfig = {
	ItemId: string,
	DisplayName: string,
	Price: number,
	Unlocks: { string }?,
	UnlockedBy: { string }?,
	ItemSlot: number?,
}

local function BeamToNextButton(props)
	local beamEnabled, setBeamEnabled = React.useState(true)
	local character, setCharacter = React.useState(player.Character)
	local itemConfigs, setItemConfigs = React.useState(nil :: { ItemConfig }?)
	local ownedItems, setOwnedItems = React.useState({})
	local beamRef = React.useRef(nil)

	-- Fetch item configs once on mount
	React.useEffect(function()
		local GetItemConfigs: RemoteFunction = game.ReplicatedStorage.Shared.Events:WaitForChild("GetItemConfigs")
		local configs = GetItemConfigs:InvokeServer()
		if configs and type(configs) == "table" then
			setItemConfigs(configs)
		end
	end, {})

	-- Fetch owned items and listen for updates
	React.useEffect(function()
		local Events = game.ReplicatedStorage.Shared.Events

		-- Get owned items
		local GetOwnedItems: RemoteFunction = Events:WaitForChild("GetOwnedItems")
		local owned = GetOwnedItems:InvokeServer()
		if owned and type(owned) == "table" then
			setOwnedItems(owned)
		end

		-- Listen for updates to owned items
		local OwnedItemsUpdated: RemoteEvent = Events:WaitForChild("OwnedItemsUpdated")
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

	-- Track character changes
	React.useEffect(function()
		setCharacter(player.Character)

		local charAddedConn = player.CharacterAdded:Connect(function(newCharacter)
			setCharacter(newCharacter)
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
				beamRef.current = nil
			end
		end)

		return function()
			if charAddedConn then
				charAddedConn:Disconnect()
			end
			if charRemovingConn then
				charRemovingConn:Disconnect()
			end
		end
	end, {})

	-- Create/Update beam to first unlocked button
	React.useEffect(function()
		-- Clean up old beam and arrow GUI, but keep attachments if they exist
		if beamRef.current then
			if beamRef.current.beam then
				beamRef.current.beam:Destroy()
			end
			if beamRef.current.arrowGui then
				beamRef.current.arrowGui:Destroy()
			end
			-- Don't destroy attachments here - they'll be reused or cleaned up on unmount
		end

		-- Don't create beam if disabled or missing requirements
		if not beamEnabled or not character or not itemConfigs then
			return
		end

		-- Find first unlocked but unowned item from config
		task.spawn(function()
			local firstUnlockedItemId = nil

			-- Find first item that is unlocked but not owned
			for _, config in ipairs(itemConfigs) do
				-- Skip if already owned
				if ownedItems[config.ItemId] then
					continue
				end
				-- if isUnlocked then
				firstUnlockedItemId = config.ItemId
				break
				-- end
			end

			if not firstUnlockedItemId then
				return
			end

			-- Wait for the ItemRenderer folder and button
			local rendererFolder = workspace:WaitForChild(player.Name .. "ItemRenderer", 10)
			if not rendererFolder then
				return
			end

			local button: Model = rendererFolder:WaitForChild("Button_" .. firstUnlockedItemId, 10)
			if not button or not button.Parent then
				return
			end

			local hrp = character:FindFirstChild("HumanoidRootPart")
			local buttonPrimary = button.PrimaryPart
				or button:FindFirstChildWhichIsA("BasePart", true)
				or button:WaitForChild("TouchPart")

			if hrp and buttonPrimary then
				-- Reuse or create att0
				local att0 = beamRef.current and beamRef.current.att0
				if not att0 or not att0.Parent then
					att0 = Instance.new("Attachment")
					att0.Parent = hrp
				end

				-- Reuse or create att1
				local att1 = beamRef.current and beamRef.current.att1
				if not att1 or not att1.Parent or att1.Parent ~= buttonPrimary then
					-- Need new att1 since button changed
					if att1 and att1.Parent then
						att1:Destroy()
					end
					att1 = Instance.new("Attachment")
					att1.Parent = buttonPrimary
				end

				local beam = Instance.new("Beam")
				beam.Attachment0 = att0
				beam.Attachment1 = att1
				beam.Width0 = 0.5
				beam.Width1 = 0.5
				beam.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
				beam.FaceCamera = true
				beam.Texture = "rbxassetid://136242854116857"
				beam.TextureSpeed = 0.3
				beam.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.5),
					NumberSequenceKeypoint.new(0.5, 0.3),
					NumberSequenceKeypoint.new(1, 0.5),
				})
				beam.Parent = hrp

				-- Clone and parent ArrowGui to att1
				local arrowGui
				local arrowGuiTemplate = game.ReplicatedStorage.Shared:FindFirstChild("ArrowGui")
				if arrowGuiTemplate and arrowGuiTemplate:IsA("BillboardGui") then
					arrowGui = arrowGuiTemplate:Clone()
					arrowGui.Parent = att1
					arrowGui.Enabled = true
				end

				-- Store for cleanup
				beamRef.current = {
					beam = beam,
					att0 = att0,
					att1 = att1,
					arrowGui = arrowGui, -- for cleanup
				}
				-- warn("Done")
			else
				-- warn("Not Done")
			end
		end)

		return function()
			-- Cleanup function - destroy everything on unmount
			if beamRef.current then
				if beamRef.current.beam then
					beamRef.current.beam:Destroy()
				end
				if beamRef.current.arrowGui then
					beamRef.current.arrowGui:Destroy()
				end
				if beamRef.current.att0 then
					beamRef.current.att0:Destroy()
				end
				if beamRef.current.att1 then
					beamRef.current.att1:Destroy()
				end
				beamRef.current = nil
			end
		end
	end, { beamEnabled, character, ownedItems, itemConfigs })

	-- Render toggle button
	return React.createElement("ImageButton", {
		Name = "NextButtonBeamToggle",
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		-- AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(1, 0, 1, 0),
		Image = "rbxassetid://136242854116857",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(30, 30, 90, 90),
		ImageTransparency = 0.4,
		ImageColor3 = beamEnabled and Color3.new(0.5, 1, 0.5) or Color3.new(1, 0.5, 0.5),
		LayoutOrder = 3,
		[React.Event.Activated] = function()
			setBeamEnabled(not beamEnabled)
		end,
	}, {
		React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		TextLabel = React.createElement("TextLabel", {
			Position = UDim2.new(0.5, 0, 1, 0),
			-- Size = UDim2.new(1, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			TextSize = 14,
			Text = beamEnabled and "Next ✓" or "Next ✗",
			Active = false,
			-- TextColor3 = beamEnabled and Color3.new(0.5, 1, 0.5) or Color3.new(1, 0.5, 0.5),
		}),
	})
end

return BeamToNextButton
