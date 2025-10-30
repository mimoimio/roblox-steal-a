--[[
	Tycoon Tree Builder Plugin v2
	- Persists data in a single ModuleScript.
	- Links configs to prefabs via path.
	- Visualizes the dependency tree in the workspace.
]]

local React = require(script.Packages.React)
local ReactRoblox = require(script.Packages.ReactRoblox)
local Alyanum = require(script.Packages.Alyanum)

-- Roblox Services
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")

-- Constants for our plugin's assets
local CONFIG_MODULE_NAME = "GeneratedItemConfigs"
local VISUALS_FOLDER_NAME = "TycoonTreeVisuals"
local DISPLAY_NAME_ATTRIBUTE = "DisplayName" -- Constant for the attribute name

-- Plugin UI
local mainWidget = plugin:CreateDockWidgetPluginGui(
	"TycoonTreeBuilder",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, true, false, 300, 400, 250, 300)
)
mainWidget.Title = "Tycoon Tree Builder v2"

local mainFrame = Instance.new("Frame", mainWidget) -- Placeholder for more complex UI
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

local toolbar = plugin:CreateToolbar("Tycoon Tree Builder")
local refreshButton = toolbar:CreateButton("Refresh", "Load/Refresh from the config module", "rbxassetid://8508980527")
local createButton = toolbar:CreateButton("Create", "Create configs from selection", "rbxassetid://109251559")
local generateButton = toolbar:CreateButton("Complete", "Save changes to the ModuleScript", "rbxassetid://732391129")

local recalculateButton =
	toolbar:CreateButton("Calculate", "Save changes to the ModuleScript", "rbxassetid://732391129")
local destroyvisualsButton =
	toolbar:CreateButton("Hide", "Save changes to the ModuleScript", "rbxassetid://112162848742561")

-- Internal state
local masterItemConfigs = {}
local existingItemIds = {}
local existingModels = {}
local onGenerateModule: () -> nil

-- ## --- Helper Function: Get or Set DisplayName --- ##
local function getOrSetDisplayName(model: Model, defaultName: string?): string
	local displayName = model:GetAttribute(DISPLAY_NAME_ATTRIBUTE)
	defaultName = defaultName or model.Name

	-- Check if attribute exists and is a non-empty string
	if displayName and typeof(displayName) == "string" and displayName ~= "" then
		return displayName
	else
		-- Attribute missing or invalid, use default (ItemId) and set the attribute
		warn("Model '" .. model.Name .. "' missing DisplayName attribute. Setting it to '" .. defaultName .. "'")
		model:SetAttribute(DISPLAY_NAME_ATTRIBUTE, defaultName)
		return defaultName
	end
end

-- Simple UID generator (incrementing integer, unique per session)
local lastUid = 0
local function generateUid()
	lastUid += 1
	return "UID_" .. ("%x"):format(tick() * 10 ^ 6 + lastUid)
end

-- ## --- Visualizer Functions --- ##
local existingVisuals = {}
local visualsFolder: Folder = workspace:FindFirstChild(VISUALS_FOLDER_NAME) or Instance.new("Folder", workspace)
visualsFolder.Name = VISUALS_FOLDER_NAME
visualsFolder.Archivable = false -- Don't save this folder with the place

-- Cleans up any existing billboards and beams
local function destroyVisuals()
	for i = #existingVisuals, 1, -1 do
		local vis = existingVisuals[i]
		vis:Destroy()
		existingVisuals[i] = nil
	end
	visualsFolder:ClearAllChildren()
end

-- Creates billboards and beams based on the current config
local function createVisuals()
	destroyVisuals() -- Always clean up before creating new ones

	local attachments = {} -- Store a map of ItemId -> Attachment Instance

	-- First, create all attachments and billboards
	for i, configData in ipairs(masterItemConfigs) do
		if configData.Prefab then
			local model: Model = configData.Prefab
			if model then
				local attachToPart = Instance.new("Part", visualsFolder) --model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
				local thisBox, thisSize = model:GetBoundingBox()
				attachToPart:PivotTo(thisBox)
				attachToPart.Size = Vector3.one * 0.01
				attachToPart.Transparency = 1
				attachToPart.Locked = true
				attachToPart.CanQuery = false
				attachToPart.CanTouch = false
				attachToPart.CanCollide = false

				if attachToPart then
					local index = i
					-- Create the attachment for the beam
					local att = Instance.new("Attachment", attachToPart)
					table.insert(existingVisuals, att)
					attachments[configData.ItemId] = att

					-- Create the BillboardGui indicator
					-- Ensure the visualsFolder exists
					if not workspace:FindFirstChild(VISUALS_FOLDER_NAME) then
						visualsFolder = Instance.new("Folder")
						visualsFolder.Name = VISUALS_FOLDER_NAME
						visualsFolder.Archivable = false
						visualsFolder.Parent = workspace
					end

					local billboard = Instance.new("BillboardGui", game:GetService("StarterGui"))
					table.insert(existingVisuals, billboard)
					billboard.Name = "ItemIndicator" .. configData.ItemId
					billboard.Size = UDim2.fromScale(2, 1)
					billboard.AlwaysOnTop = true
					billboard.LightInfluence = 0
					billboard.Adornee = attachToPart
					billboard.Active = true
					billboard.SizeOffset = Vector2.new(0.5, 0)

					local nameBox = Instance.new("TextBox", billboard)
					nameBox.Size = UDim2.new(1, 0, 0.3, 0)
					nameBox.Text = configData.ItemId
					nameBox.TextScaled = true
					nameBox.BackgroundTransparency = 0.5
					nameBox.BackgroundColor3 = Color3.new(0, 0, 0)
					nameBox.TextColor3 = Color3.new(1, 1, 1)
					nameBox.LayoutOrder = 1
					nameBox.TextEditable = false
					nameBox.ClearTextOnFocus = false
					-- nameBox.FocusLost:Connect(function(enterpressed)
					-- 	local name: string = tostring(nameBox.Text)
					-- 	if not name or name:len() == 0 then
					-- 		nameBox.Text = configData.ItemId
					-- 		return
					-- 	end
					-- 	local alreadyused
					-- 	for j, itemconfig in masterItemConfigs do
					-- 		alreadyused = itemconfig.ItemId == name
					-- 		if alreadyused then
					-- 			break
					-- 		end
					-- 	end
					-- 	if alreadyused then
					-- 		warn("NAME ALREADY BEING USED")
					-- 		nameBox.Text = configData.ItemId
					-- 		return
					-- 	end

					-- 	for j, itemconfig in masterItemConfigs do
					-- 		if not itemconfig.Unlocks or type(itemconfig.Unlocks) ~= "table" then
					-- 			continue
					-- 		end
					-- 		local foundat = table.find(itemconfig.Unlocks, configData.Prefab.Name)
					-- 		if foundat then
					-- 			itemconfig.Unlocks[foundat] = name
					-- 		end
					-- 	end
					-- 	configData.ItemId = name
					-- 	configData.Prefab.Name = name
					-- 	onGenerateModule()
					-- end)

					local label = Instance.new("TextBox", billboard)
					label.Size = UDim2.new(1, 0, 0.3, 0)
					-- *** CHANGE: Use DisplayName here ***
					label.Text = configData.DisplayName or "**" .. configData.ItemId -- Fallback just in case
					label.TextScaled = true
					label.Name = "DisplayNameBox"
					nameBox.Name = "ItemIdBox"
					label.BackgroundTransparency = 0.5
					label.BackgroundColor3 = Color3.new(0, 0, 0)
					label.LayoutOrder = 3
					label.ClearTextOnFocus = false
					label.TextColor3 = Color3.new(1, 1, 1)
					label.FocusLost:Connect(function(enterpressed)
						local name: string = tostring(label.Text)
						if not name or name:len() == 0 or name == "" then
							label.Text = configData.DisplayName or "**" .. configData.ItemId -- Fallback just in case
							return
						end
						configData.DisplayName = name
						model:SetAttribute(DISPLAY_NAME_ATTRIBUTE, name)
						onGenerateModule()
					end)
					-- Previous button
					local prevButton = Instance.new("TextButton", nameBox)
					prevButton.TextScaled = true
					prevButton.Size = UDim2.new(0.15, 0, 1, 0)
					prevButton.Position = UDim2.new(0, 0, 0, 0)
					prevButton.AnchorPoint = Vector2.new(0, 0)
					prevButton.Text = "<"
					prevButton.BackgroundTransparency = 0.3
					prevButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
					prevButton.TextColor3 = Color3.new(1, 1, 1)
					prevButton.Font = Enum.Font.SourceSansBold
					prevButton.TextSize = 18
					prevButton.Activated:Connect(function()
						local prevIndex = i - 1
						if prevIndex >= 1 and masterItemConfigs[prevIndex] and masterItemConfigs[prevIndex].Prefab then
							local prevModel: Model = masterItemConfigs[prevIndex].Prefab
							local prevPart = prevModel.PrimaryPart or prevModel:FindFirstChildWhichIsA("BasePart", true)
							local prevBoxCFrame, prevBoxSize = prevModel:GetBoundingBox()
							if prevPart then
								local camera = workspace.CurrentCamera
								camera.CameraType = Enum.CameraType.Scriptable
								local targetPos = prevBoxCFrame.Position
								local offset = camera.CFrame.LookVector * 10 --[[+ 0.1 * prevBoxSize.Magnitude]]
								camera.CFrame = CFrame.new(targetPos - offset, targetPos)
								camera.Focus = CFrame.new(targetPos)
								Selection:Set({ prevModel })
								camera.CameraType = Enum.CameraType.Custom
							end
						end
					end)

					-- Next button
					local nextButton = Instance.new("TextButton", nameBox)
					nextButton.Size = UDim2.new(0.15, 0, 1, 0)
					nextButton.Position = UDim2.new(1, 0, 0, 0)
					nextButton.TextScaled = true
					nextButton.AnchorPoint = Vector2.new(1, 0)
					nextButton.Text = ">"
					nextButton.BackgroundTransparency = 0.3
					nextButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
					nextButton.TextColor3 = Color3.new(1, 1, 1)
					nextButton.Font = Enum.Font.SourceSansBold
					nextButton.TextSize = 18
					nextButton.Activated:Connect(function()
						local nextIndex = i + 1
						if
							nextIndex <= #masterItemConfigs
							and masterItemConfigs[nextIndex]
							and masterItemConfigs[nextIndex].Prefab
						then
							local nextModel: Model = masterItemConfigs[nextIndex].Prefab
							local nextPart = nextModel.PrimaryPart or nextModel:FindFirstChildWhichIsA("BasePart", true)
							local nextBoxCFrame, nextBoxSize = nextModel:GetBoundingBox()
							if nextPart then
								local camera = workspace.CurrentCamera
								camera.CameraType = Enum.CameraType.Scriptable
								local targetPos = nextBoxCFrame.Position
								local offset = camera.CFrame.LookVector * 10 --[[+ 0.1 * prevBoxSize.Magnitude]]
								camera.CFrame = CFrame.new(targetPos - offset, targetPos)
								camera.Focus = CFrame.new(targetPos)
								Selection:Set({ nextModel })
								camera.CameraType = Enum.CameraType.Custom
							end
						end
					end)

					local PriceBox = Instance.new("TextBox", billboard)
					PriceBox.TextEditable = true
					PriceBox.TextScaled = true
					PriceBox.Size = UDim2.new(1, 0, 0.3, 0)
					PriceBox.Text = configData.Price
					PriceBox.BackgroundTransparency = 0.5
					PriceBox.BackgroundColor3 = Color3.new(0, 0, 0)
					PriceBox.TextColor3 = Color3.new(1, 1, 1)
					PriceBox.Name = "PriceBox"
					PriceBox.FocusLost:Connect(function(enterpressed)
						local num = tonumber(PriceBox.Text)
						if not num then
							PriceBox.Text = configData.Price
							return
						end
						configData.Price = num
						onGenerateModule()
					end)
					PriceBox.LayoutOrder = 2

					local deletebutton = Instance.new("TextButton", PriceBox)
					deletebutton.Size = UDim2.new(0.15, 0, 1, 0)
					deletebutton.TextScaled = true
					deletebutton.AnchorPoint = Vector2.new(1, 0)
					deletebutton.Position = UDim2.new(1, 0, 0, 0)
					deletebutton.Text = "Dlt"
					deletebutton.BackgroundTransparency = 0.5
					deletebutton.BackgroundColor3 = Color3.new(1, 0, 0)
					deletebutton.TextColor3 = Color3.new(1, 1, 1)
					deletebutton.Activated:Connect(function(inputObject, clickCount)
						local thisConfig = table.remove(masterItemConfigs, i)

						for j, itemconfig in masterItemConfigs do
							if not itemconfig.Unlocks or type(itemconfig.Unlocks) ~= "table" then
								continue
							end
							existingModels[itemconfig.Prefab] = nil
							local foundat = table.find(itemconfig.Unlocks, thisConfig.Prefab.Name)
							if foundat then
								table.remove(itemconfig.Unlocks, foundat)
							end
						end
						onGenerateModule()
					end)

					local NumberBox = Instance.new("TextBox", PriceBox)
					NumberBox.TextEditable = true
					NumberBox.TextScaled = true
					NumberBox.Size = UDim2.new(0.15, 0, 1, 0)
					NumberBox.Text = index
					NumberBox.BackgroundTransparency = 0.5
					NumberBox.BackgroundColor3 = Color3.new(0, 0, 0)
					NumberBox.TextColor3 = Color3.new(1, 1, 1)
					NumberBox.Name = "IndexBox"
					NumberBox.FocusLost:Connect(function(enterpressed)
						local num = tonumber(NumberBox.Text)
						if not num then
							NumberBox.Text = index
							return
						end

						local currentIndex = index
						local targetIndex = num
						if targetIndex <= 0 or targetIndex >= #masterItemConfigs then
							warn("Outside of total indexes!")
							NumberBox.Text = index
							return
						end
						if targetIndex == 1 or currentIndex == 1 then
							warn("PREVENT CHANGING ON ROOT ITEMS")
							NumberBox.Text = index
							return
						end
						if masterItemConfigs[targetIndex].Unlocks or masterItemConfigs[currentIndex].Unlocks then
							warn("PREVENT CHANGING ON UNLOCKS ITEM")
							NumberBox.Text = index
							return
						end

						-- if the target is bigger, simply swap from current to the target
						if targetIndex > currentIndex then
							local tempConfig = masterItemConfigs[targetIndex]
							masterItemConfigs[targetIndex] = masterItemConfigs[currentIndex]
							masterItemConfigs[currentIndex] = tempConfig

						-- if target is smaller, remove current, and insert at target, therefore pushing forward the rest
						elseif targetIndex < currentIndex then
							local itemToMove = table.remove(masterItemConfigs, currentIndex)
							table.insert(masterItemConfigs, targetIndex, itemToMove)
							index = targetIndex
						else -- currentindex == targetindex
							return
						end
						onGenerateModule()
					end)

					local UIListLayout = Instance.new("UIListLayout", billboard)
					UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

					local button = workspace.Button:Clone()
					table.insert(existingVisuals, button)
					button:PivotTo(configData.Prefab:GetPivot())
					button.Parent = visualsFolder
					button.PrimaryPart.BillboardGui.TextLabel.Text = configData.DisplayName or configData.ItemId
					button.Changed:Connect(function(property)
						--warn(property, button[property])
						if property ~= "WorldPivot" then
							return
						end
						warn("done")
						configData.Prefab.WorldPivot = button[property]
					end)
				else
					warn("NO BASEPART IN THE MODEL", model)
				end
			end
		end
	end

	-- Second, create all the beams now that attachments exist
	for i, configData in ipairs(masterItemConfigs) do
		if configData.Unlocks and attachments[configData.ItemId] then
			local parentAttachment = attachments[configData.ItemId]
			for i, unlockId in ipairs(configData.Unlocks) do
				local childAttachment = attachments[unlockId]
				if childAttachment then
					local beam = Instance.new("Beam", visualsFolder)
					beam.Attachment0 = parentAttachment
					beam.Attachment1 = childAttachment
					beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 127))
					beam.LightInfluence = 0
					beam.Width0 = 0.5
					beam.Width1 = 0.5
					beam.FaceCamera = true
					table.insert(existingVisuals, beam)
				end
			end
		end
	end
end

function recalculatePrices()
	local baseCost = 50 -- The cost of the second item (index 2)
	local multiplier = 1.07 -- Each item will cost 12% more than the last

	masterItemConfigs[1].Price = 0

	for i = 2, #masterItemConfigs do
		local itemconfig = masterItemConfigs[i]

		-- The new price is the baseCost multiplied by the multiplier,
		-- raised to the power of its position in the list.
		itemconfig.Price = math.floor(baseCost * (multiplier ^ (i - 2)))
	end

	onGenerateModule()
end

-- ## --- Core Logic --- ##
-- Tries to load and parse the existing ModuleScript
local function onRefresh()
	--[[TODO: HANDLE ITEM NOT FOUND.]]
	masterItemConfigs = {}
	existingItemIds = {}
	existingModels = {}
	destroyVisuals()

	local configModule = ServerScriptService:FindFirstChild(CONFIG_MODULE_NAME)
	if configModule then
		-- *** CRITICAL FIX: Handle the 'require' cache ***
		-- 'require' caches modules. We must get a fresh copy of the
		-- code and load it ourselves to see changes.

		local success, result = pcall(function()
			-- Create a temporary module to bypass the cache
			local tempModule = Instance.new("ModuleScript")
			tempModule.Source = configModule.Source
			tempModule.Parent = script -- Parent to plugin script
			local data = require(tempModule)
			tempModule:Destroy()
			return data
		end)

		if success and typeof(result) == "table" then
			masterItemConfigs = result
			-- Populate the quick-lookup dictionary
			for _, config in ipairs(masterItemConfigs) do
				existingItemIds[config.ItemId] = config
				if config.Prefab then
					existingModels[config.Prefab] = config
				else
					warn("NO PREFAB FOUND")
				end
				-- *** ADDITION: Ensure DisplayName attribute exists on load ***
				if config.Prefab and config.Prefab:IsA("Instance") and config.Prefab.Parent then
					-- Use the helper function to check/set the attribute
					-- We prioritize the DisplayName saved in the config, but fallback to ItemId
					local expectedDisplayName = config.DisplayName or config.ItemId
					getOrSetDisplayName(config.Prefab, expectedDisplayName)
				else
					warn(
						"Could not validate DisplayName attribute for "
							.. config.ItemId
							.. " - Prefab missing or invalid."
					)
				end
			end
			print("✅ Loaded " .. #masterItemConfigs .. " items from module.")
		else
			warn("⚠️ Failed to load or parse module. Starting fresh.", result)
		end
	else
		print("🌳 No config module found. Starting a new tree.")
	end
	createVisuals()
end
-- Generates the Luau source code and writes it to the module
onGenerateModule = function()
	local lines = {}
	table.insert(lines, "-- Generated by Tycoon Tree Builder Plugin v2")
	table.insert(lines, "return {")

	for i, configData in ipairs(masterItemConfigs) do
		table.insert(lines, "\t{")
		table.insert(lines, string.format('\t\tItemId = "%s",', configData.ItemId))
		-- *** ADDITION: Serialize DisplayName ***
		-- Use escaping for quotes within the display name itself if needed
		table.insert(
			lines,
			string.format('\t\tDisplayName = "%s",', (configData.DisplayName or configData.ItemId):gsub('"', '\\"'))
		)
		table.insert(lines, string.format("\t\tPrice = %d,", configData.Price or 0))

		-- Add the new Prefab attribute
		if configData.Prefab then
			-- right now just use workspace.Items folder, dont need to use GetFullName()
			table.insert(lines, string.format('\t\tPrefab = workspace.Items:FindFirstChild("%s"),', configData.ItemId))
		end

		if configData.Unlocks and #configData.Unlocks > 0 then
			table.insert(lines, "\t\tUnlocks = {")
			for i, unlockId in ipairs(configData.Unlocks) do
				table.insert(lines, string.format('\t\t\t"%s",', unlockId))
			end
			table.insert(lines, "\t\t},")
		end
		table.insert(lines, "\t},")
	end

	table.insert(lines, "}")
	local finalSource = table.concat(lines, "\n")

	local configModule = ServerScriptService:FindFirstChild(CONFIG_MODULE_NAME)
	if not configModule then
		configModule = Instance.new("ModuleScript", ServerScriptService)
		configModule.Name = CONFIG_MODULE_NAME
	end

	configModule.Source = finalSource
	Selection:Set({ configModule })
	print("💾 Saved configuration to " .. CONFIG_MODULE_NAME)
	createVisuals() -- Refresh visuals after saving
end

local modelLookup

-- Creates new configs based on selection
local function onCreateFromSelection()
	local selection = Selection:Get()
	for i, selected: Instance in selection do
		if selected:IsA("Model") then
			continue
		end
		task.spawn(function()
			error("PLEASE SELECT ONLY MODELS")
		end)
		return
	end
	if #selection < 1 then
		return
	end

	local rootModel: Model = selection[1]
	rootModel.Name = rootModel.Name:gsub(" ", ""):gsub('"', "")
	local rootId = rootModel.Name
	local rootConfig = nil

	for i, config in ipairs(masterItemConfigs) do
		if config.ItemId == rootId then
			rootConfig = config
			break
		end
	end

	if not rootConfig then
		rootConfig = {
			ItemId = rootId,
			Price = 40 + #masterItemConfigs * 5,
			Prefab = rootModel, -- Link the prefab
			DisplayName = rootId,
		}
		table.insert(masterItemConfigs, rootConfig)
		existingItemIds[rootId] = true
	end
	warn(rootModel, rootConfig)

	if #selection > 1 then
		if not rootConfig.Unlocks then
			rootConfig.Unlocks = {}
		end

		-- starting from 2, configs for the rest of the selections.
		for i = 2, #selection do
			local childModel: Model = selection[i]
			childModel.Name = childModel.Name:gsub(" ", ""):gsub('"', "")
			if not existingModels[childModel] then -- --- START: New logic to handle duplicates ---
				local DisplayName = getOrSetDisplayName(childModel)
				local childId = generateUid()
				local uniqueChildId = childId
				local counter = 1
				-- Keep checking for a new ID as long as the current one exists
				while existingItemIds[uniqueChildId] do
					-- Create a new name, e.g., "MyItem_1", "MyItem_2", etc.
					uniqueChildId = generateUid()
					counter = counter + 1
				end

				-- Optional: Warn if a rename actually happened
				if uniqueChildId ~= childId then
					warn("Item '" .. childId .. "' already exists. Renaming to '" .. uniqueChildId .. "'.")
				end
				childModel.Name = uniqueChildId
				-- --- END: New logic ---

				-- Now, we use 'uniqueChildId' which is guaranteed to be unique
				table.insert(rootConfig.Unlocks, uniqueChildId)
				local childConfig = {
					ItemId = uniqueChildId, -- Use the new unique ID
					Price = 40 + #masterItemConfigs * 5,
					Prefab = childModel, -- Link the prefab
					DisplayName = DisplayName, -- Use the new unique ID
				}
				table.insert(masterItemConfigs, childConfig)

				-- Register the new unique ID so it's caught on the next loop
				existingItemIds[uniqueChildId] = true
			else
				warn("Model", childModel, "already being used")
			end
		end
	end

	print("✅ Processed selection with root: " .. rootId)
	createVisuals() -- Refresh visuals after creating
	onGenerateModule()
end

-- Connect button clicks to functions
refreshButton.Click:Connect(onRefresh)
createButton.Click:Connect(onCreateFromSelection)
generateButton.Click:Connect(onGenerateModule)
destroyvisualsButton.Click:Connect(destroyVisuals)
recalculateButton.Click:Connect(recalculatePrices)
-- Handle plugin activation/deactivation
mainWidget.Changed:Connect(function(property)
	if property ~= "Enabled" then
		return
	end

	if mainWidget.Enabled then
		onRefresh()
	else
		destroyVisuals()
	end
end)

plugin.Unloading:Connect(destroyVisuals)
