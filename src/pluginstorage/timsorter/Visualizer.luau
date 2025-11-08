--[[
	Visualizer Component
	Renders billboards and beams for selected item and its unlocks
]]

local React = require(script.Parent.Packages.React)
local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef

type ItemConfig = {
	ItemId: string,
	DisplayName: string?,
	Price: number,
	Unlocks: { string }?,
	UnlockedBy: { string }?,
	Prefab: Model?,
	ItemSlot: number?,
}

type VisualizerProps = {
	enabled: boolean,
	selectedConfig: ItemConfig?,
	configLookup: { [string]: ItemConfig },
	selectedUnlockIndex: number?,
	onSelectUnlock: (index: number) -> (),
	onNavigatePrevious: () -> (),
	onNavigateNext: () -> (),
	onGoToItem: (itemId: string) -> (),
}

local VISUALS_FOLDER_NAME = "TimSorterVisuals"

local function Visualizer(props: VisualizerProps)
	local visualsRef = useRef({})

	useEffect(function()
		-- Cleanup function
		local function cleanup()
			for _, visual in ipairs(visualsRef.current) do
				if visual and visual.Parent then
					visual:Destroy()
				end
			end
			visualsRef.current = {}
		end

		-- Don't create visuals if disabled or no selection
		if not props.enabled or not props.selectedConfig then
			cleanup()
			return cleanup
		end

		local selectedConfig = props.selectedConfig

		-- Ensure visuals folder exists
		local visualsFolder = workspace:FindFirstChild(VISUALS_FOLDER_NAME)
		if not visualsFolder then
			visualsFolder = Instance.new("Folder")
			visualsFolder.Name = VISUALS_FOLDER_NAME
			visualsFolder.Archivable = false
			visualsFolder.Parent = workspace
		end

		-- Clear old visuals
		cleanup()

		-- Helper to create billboard
		local function createBillboard(model: Model, config: ItemConfig, isSelected: boolean)
			local boxCFrame, boxSize = model:GetBoundingBox()

			-- Create invisible part for attachment
			local attachPart = Instance.new("Part")
			attachPart.Transparency = 1
			attachPart.CanCollide = false
			attachPart.CanQuery = false
			attachPart.CanTouch = false
			attachPart.Anchored = true
			attachPart.Size = Vector3.new(0.01, 0.01, 0.01)
			attachPart:PivotTo(boxCFrame)
			attachPart.Parent = visualsFolder
			table.insert(visualsRef.current, attachPart)

			-- Create attachment for beams
			local attachment = Instance.new("Attachment")
			attachment.Parent = attachPart

			-- Create billboard
			local billboard = Instance.new("BillboardGui")
			billboard.Size = UDim2.fromScale(2, 1)
			billboard.AlwaysOnTop = true
			billboard.LightInfluence = 0
			billboard.Adornee = attachPart
			billboard.SizeOffset = Vector2.new(0.5, 0)
			billboard.Parent = game:GetService("StarterGui")
			table.insert(visualsRef.current, billboard)

			-- Create UI elements
			local layout = Instance.new("UIListLayout")
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = billboard

			-- ItemId box
			local itemIdBox = Instance.new("TextBox")
			itemIdBox.Size = UDim2.new(1, 0, 0.3, 0)
			itemIdBox.Text = config.ItemId
			itemIdBox.TextScaled = true
			itemIdBox.BackgroundTransparency = 0.5
			itemIdBox.BackgroundColor3 = Color3.new(0, 0, 0)
			itemIdBox.TextColor3 = Color3.new(1, 1, 1)
			itemIdBox.LayoutOrder = 1
			itemIdBox.TextEditable = false
			itemIdBox.Name = "ItemIdBox"
			itemIdBox.Parent = billboard

			-- DisplayName box
			local displayNameBox = Instance.new("TextBox")
			displayNameBox.Size = UDim2.new(1, 0, 0.3, 0)
			displayNameBox.Text = config.DisplayName or config.ItemId
			displayNameBox.TextScaled = true
			displayNameBox.BackgroundTransparency = 0.5
			displayNameBox.BackgroundColor3 = Color3.new(0, 0, 0)
			displayNameBox.TextColor3 = Color3.new(1, 1, 1)
			displayNameBox.LayoutOrder = 3
			displayNameBox.TextEditable = false
			displayNameBox.Name = "DisplayNameBox"
			displayNameBox.Parent = billboard

			-- Price box
			local priceBox = Instance.new("TextBox")
			priceBox.Size = UDim2.new(1, 0, 0.3, 0)
			priceBox.Text = tostring(config.Price)
			priceBox.TextScaled = true
			priceBox.BackgroundTransparency = 0.5
			priceBox.BackgroundColor3 = Color3.new(0, 0, 0)
			priceBox.TextColor3 = Color3.new(1, 1, 1)
			priceBox.LayoutOrder = 2
			priceBox.TextEditable = false
			priceBox.Name = "PriceBox"
			priceBox.Parent = billboard

			-- Add navigation buttons if this is the selected item
			if isSelected then
				local prevButton = Instance.new("TextButton")
				prevButton.Size = UDim2.new(0.15, 0, 1, 0)
				prevButton.Position = UDim2.new(0, 0, 0, 0)
				prevButton.AnchorPoint = Vector2.new(0, 0)
				prevButton.Text = "<"
				prevButton.TextScaled = true
				prevButton.BackgroundTransparency = 0.3
				prevButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
				prevButton.TextColor3 = Color3.new(1, 1, 1)
				prevButton.Font = Enum.Font.SourceSansBold
				prevButton.Activated:Connect(props.onNavigatePrevious)
				prevButton.Parent = itemIdBox

				local nextButton = Instance.new("TextButton")
				nextButton.Size = UDim2.new(0.15, 0, 1, 0)
				nextButton.Position = UDim2.new(1, 0, 0, 0)
				nextButton.AnchorPoint = Vector2.new(1, 0)
				nextButton.Text = ">"
				nextButton.TextScaled = true
				nextButton.BackgroundTransparency = 0.3
				nextButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
				nextButton.TextColor3 = Color3.new(1, 1, 1)
				nextButton.Font = Enum.Font.SourceSansBold
				nextButton.Activated:Connect(props.onNavigateNext)
				nextButton.Parent = itemIdBox
			end

			-- Add highlight
			local highlight = Instance.new("Highlight")
			highlight.FillTransparency = 1
			highlight.OutlineColor = isSelected and Color3.new(0.5, 1, 0.5) or Color3.new(0.5, 0.5, 1)
			highlight.FillColor = Color3.new(1, 1, 1)
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			highlight.Parent = model
			table.insert(visualsRef.current, highlight)

			return attachment
		end

		-- Create visual for selected item
		if not selectedConfig.Prefab then
			warn("⚠️ Selected config has no Prefab:", selectedConfig.ItemId)
			return cleanup
		end

		local selectedModel: Model = selectedConfig.Prefab
		local selectedAttachment = createBillboard(selectedModel, selectedConfig, true)

		-- Create visuals for each unlock
		if selectedConfig.Unlocks then
			for i, unlockId in ipairs(selectedConfig.Unlocks) do
				local unlockConfig = props.configLookup[unlockId]
				if unlockConfig and unlockConfig.Prefab then
					local unlockModel: Model = unlockConfig.Prefab
					local unlockAttachment = createBillboard(unlockModel, unlockConfig, i == props.selectedUnlockIndex)

					-- Create beam from selected to unlock
					local beam = Instance.new("Beam")
					beam.Attachment0 = selectedAttachment
					beam.Attachment1 = unlockAttachment
					beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 127))
					beam.LightInfluence = 0
					beam.Width0 = 0.5
					beam.Width1 = 0.5
					beam.FaceCamera = true
					beam.Parent = visualsFolder
					table.insert(visualsRef.current, beam)

					-- Make billboard clickable to select unlock
					local billboard = unlockAttachment.Parent:FindFirstChildOfClass("BillboardGui")
					if billboard then
						local clickDetector = Instance.new("ClickDetector")
						clickDetector.MaxActivationDistance = 1000
						clickDetector.MouseClick:Connect(function()
							props.onSelectUnlock(i)
						end)
						clickDetector.Parent = unlockAttachment.Parent
						table.insert(visualsRef.current, clickDetector)
					end
				else
					warn("⚠️ Unlock config not found or has no Prefab:", unlockId)
				end
			end
		end

		return cleanup
	end, { props.enabled, props.selectedConfig, props.selectedUnlockIndex })

	return nil
end

return Visualizer
