--[[
	Tycoon Tree Builder Plugin v2
	- Persists data in a single ModuleScript.
	- Links configs to prefabs via path.
	- Visualizes the dependency tree in the workspace.
]]

if not game.GameId == 8782368102 then
	warn("This plugin is specific to one game currently")
	return
end

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
local BACKUPS_FOLDER_NAME = "GeneratedItemConfigsBackups" -- Backups folder for periodic snapshots

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

local destroyvisualsButton =
	toolbar:CreateButton("Hide", "Save changes to the ModuleScript", "rbxassetid://112162848742561")
local togglePlugin = toolbar:CreateButton("Toggle", "", "rbxassetid://112162848742561")
local bfsSortButton = toolbar:CreateButton("BFS Sort", "Sort configs using BFS traversal", "rbxassetid://732391129")
local dfsSortButton = toolbar:CreateButton("DFS Sort", "Sort configs using DFS traversal", "rbxassetid://732391129")

-- Internal state
local masterItemConfigs = {}
local existingItemIds = {}
local existingModels = {}
local onGenerateModule: () -> nil
local generateCount = 0 -- counts how many times we generate; backup every 5

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

local visible = false

-- Cleans up any existing billboards and beams
local function destroyVisuals()
	for i = #existingVisuals, 1, -1 do
		local vis = existingVisuals[i]
		vis:Destroy()
		existingVisuals[i] = nil
	end
	visualsFolder:ClearAllChildren()
end
mainWidget.Enabled = visible
local toggleVisible = function()
	local itemfolder = workspace.Items :: ObjectValue
	local OriginalBase = workspace.OriginalBase :: ObjectValue
	if visible then -- closing
		onGenerateModule()
		destroyVisuals()
		mainWidget.Enabled = false
		itemfolder.Value.Parent = game.ServerStorage
		OriginalBase.Value.Parent = game.ServerStorage
	else
		mainWidget.Enabled = true
		itemfolder.Value.Parent = workspace
		OriginalBase.Value.Parent = workspace
	end
	visible = not visible
end
togglePlugin.Click:Connect(toggleVisible)

-- Wrap operations to return if not visible
local function ensureVisible(fn)
	return function(...)
		if not visible then
			warn("Turn on the plugin first")
			return
		end
		return fn(...)
	end
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
					if configData.ItemSlot then
						local itemSlotBillboard = game.ReplicatedStorage.Shared.BillboardGui:Clone()
						itemSlotBillboard.TextLabel.Text = "ITEMSLOT" .. configData.ItemSlot
						itemSlotBillboard.Adornee = attachToPart
						itemSlotBillboard.Parent = game.StarterGui
						table.insert(existingVisuals, itemSlotBillboard)

						local hil = Instance.new("Highlight", model)
						table.insert(existingVisuals, hil)
					end

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
						existingModels[thisConfig.Prefab] = nil
						existingItemIds[thisConfig.ItemId] = nil

						-- deleting thisconfig from any children it has
						local unlocks = thisConfig.Unlocks
						if unlocks then
							for i, unlock in ipairs(unlocks) do
								for j, itemconfig in ipairs(masterItemConfigs) do
									if itemconfig.ItemId == unlock then
										-- existingModels[itemconfig.Prefab] = nil
										-- existingItemIds[itemconfig.ItemId] = nil
										local found = table.find(itemconfig.UnlockedBy, thisConfig.ItemId)
										if found then
											table.remove(itemconfig.UnlockedBy, found)
										end
									end
								end
							end
						end

						-- deleting from any unlocks
						for j, itemconfig in masterItemConfigs do
							if not itemconfig.Unlocks or type(itemconfig.Unlocks) ~= "table" then
								continue
							end
							local foundat = table.find(itemconfig.Unlocks, thisConfig.ItemId)
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
							warn("PREVENT CHANGING ON ROOT ITEM")
							NumberBox.Text = index
							return
						end
						-- if masterItemConfigs[targetIndex].Unlocks or masterItemConfigs[currentIndex].Unlocks then
						-- 	warn("PREVENT CHANGING ON UNLOCKS ITEM")
						-- 	NumberBox.Text = index
						-- 	return
						-- end

						-- if the target is bigger, move the current item after the target (push backward)
						if targetIndex > currentIndex then
							local itemToMove = table.remove(masterItemConfigs, currentIndex)
							-- After removal, targetIndex decreases by 1 if it was after currentIndex
							table.insert(masterItemConfigs, targetIndex, itemToMove)
							index = targetIndex

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

					local button = workspace.Button.Value:Clone()
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

-- Performs a breadth-first search traversal and returns a new sorted config array
local function bfsSortConfigs(configs: { any }): { any }
	if not configs or #configs == 0 then
		warn("No configs to sort")
		return {}
	end

	-- Build a lookup table: ItemId -> config
	local configLookup = {}
	for _, config in ipairs(configs) do
		configLookup[config.ItemId] = config
	end

	-- Find the root node (the one with no UnlockedBy or empty UnlockedBy)
	local rootConfig = nil
	for _, config in ipairs(configs) do
		if not config.UnlockedBy or #config.UnlockedBy == 0 then
			rootConfig = config
			break
		end
	end

	if not rootConfig then
		warn("⚠️ No root node found (config with no UnlockedBy). Cannot perform BFS sort.")
		return configs -- Return original if no root found
	end

	-- BFS traversal
	local sortedConfigs = {}
	local visited = {}
	local queue = { rootConfig }

	while #queue > 0 do
		-- Dequeue
		local current = table.remove(queue, 1)

		-- Skip if already visited
		if not visited[current.ItemId] then
			visited[current.ItemId] = true
			table.insert(sortedConfigs, current)

			-- Enqueue all children (items in Unlocks array)
			if current.Unlocks and type(current.Unlocks) == "table" then
				for _, unlockId in ipairs(current.Unlocks) do
					local childConfig = configLookup[unlockId]
					if childConfig and not visited[unlockId] then
						table.insert(queue, childConfig)
					end
				end
			end
		end
	end

	-- Check if all configs were visited (in case of disconnected nodes)
	if #sortedConfigs < #configs then
		warn(
			"⚠️ BFS sort only found "
				.. #sortedConfigs
				.. " out of "
				.. #configs
				.. " configs. Some nodes may be disconnected from the root."
		)
		-- Add any unvisited nodes at the end
		for _, config in ipairs(configs) do
			if not visited[config.ItemId] then
				table.insert(sortedConfigs, config)
				warn("  Adding disconnected node: " .. config.ItemId)
			end
		end
	end

	return sortedConfigs
end

-- Function to generate a BFS-sorted module
local function generateBFSSortedModule()
	local configs
	local configModule = ServerScriptService:FindFirstChild(CONFIG_MODULE_NAME)
	if configModule then
		local success, result = pcall(function()
			local tempModule = Instance.new("ModuleScript")
			tempModule.Source = configModule.Source
			tempModule.Parent = script
			local data = require(tempModule)
			tempModule:Destroy()
			return data
		end)

		if success and typeof(result) == "table" then
			configs = result
		else
			warn("⚠️ Failed to load or parse module.", result)
			return
		end
	else
		warn("No config module found")
		return
	end

	-- Perform BFS sort
	local sortedConfigs = bfsSortConfigs(configs)

	-- Update master configs
	masterItemConfigs = sortedConfigs

	-- Generate the new module with sorted order
	onGenerateModule()

	print("✅ BFS sort complete! Configs reordered based on dependency tree.")
end

-- Performs a depth-first search traversal and returns a new sorted config array
local function dfsSortConfigs(configs: { any }): { any }
	if not configs or #configs == 0 then
		warn("No configs to sort")
		return {}
	end

	-- Build a lookup table: ItemId -> config
	local configLookup = {}
	for _, config in ipairs(configs) do
		configLookup[config.ItemId] = config
	end

	-- Find the root node (the one with no UnlockedBy or empty UnlockedBy)
	local rootConfig = nil
	for _, config in ipairs(configs) do
		if not config.UnlockedBy or #config.UnlockedBy == 0 then
			rootConfig = config
			break
		end
	end

	if not rootConfig then
		warn("⚠️ No root node found (config with no UnlockedBy). Cannot perform DFS sort.")
		return configs -- Return original if no root found
	end

	-- DFS traversal using recursion
	local sortedConfigs = {}
	local visited = {}

	local function dfsVisit(config)
		if visited[config.ItemId] then
			return
		end

		visited[config.ItemId] = true
		table.insert(sortedConfigs, config)

		-- Recursively visit all children (items in Unlocks array)
		if config.Unlocks and type(config.Unlocks) == "table" then
			for _, unlockId in ipairs(config.Unlocks) do
				local childConfig = configLookup[unlockId]
				if childConfig and not visited[unlockId] then
					dfsVisit(childConfig)
				end
			end
		end
	end

	-- Start DFS from root
	dfsVisit(rootConfig)

	-- Check if all configs were visited (in case of disconnected nodes)
	if #sortedConfigs < #configs then
		warn(
			"⚠️ DFS sort only found "
				.. #sortedConfigs
				.. " out of "
				.. #configs
				.. " configs. Some nodes may be disconnected from the root."
		)
		-- Add any unvisited nodes at the end
		for _, config in ipairs(configs) do
			if not visited[config.ItemId] then
				table.insert(sortedConfigs, config)
				warn("  Adding disconnected node: " .. config.ItemId)
			end
		end
	end

	return sortedConfigs
end

-- Function to generate a DFS-sorted module
local function generateDFSSortedModule()
	local configs
	local configModule = ServerScriptService:FindFirstChild(CONFIG_MODULE_NAME)
	if configModule then
		local success, result = pcall(function()
			local tempModule = Instance.new("ModuleScript")
			tempModule.Source = configModule.Source
			tempModule.Parent = script
			local data = require(tempModule)
			tempModule:Destroy()
			return data
		end)

		if success and typeof(result) == "table" then
			configs = result
		else
			warn("⚠️ Failed to load or parse module.", result)
			return
		end
	else
		warn("No config module found")
		return
	end

	-- Perform DFS sort
	local sortedConfigs = dfsSortConfigs(configs)

	-- Update master configs
	masterItemConfigs = sortedConfigs

	-- Generate the new module with sorted order
	onGenerateModule()

	print("✅ DFS sort complete! Configs reordered based on dependency tree.")
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

	if #masterItemConfigs < 1 then
		warn("Error: no overwriting with empty configs")
		return
	end

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
			table.insert(
				lines,
				string.format('\t\tPrefab = workspace.Items.Value:FindFirstChild("%s"),', configData.ItemId)
			)
		end

		if configData.Unlocks and #configData.Unlocks > 0 then
			table.insert(lines, "\t\tUnlocks = {")
			for i, unlockId in ipairs(configData.Unlocks) do
				table.insert(lines, string.format('\t\t\t"%s",', unlockId))
			end
			table.insert(lines, "\t\t},")
		end
		if configData.UnlockedBy and #configData.UnlockedBy > 0 then
			table.insert(lines, "\t\tUnlockedBy = {")
			for i, unlockId in ipairs(configData.UnlockedBy) do
				table.insert(lines, string.format('\t\t\t"%s",', unlockId))
			end
			table.insert(lines, "\t\t},")
		end
		if configData.ItemSlot ~= nil then
			if type(configData.ItemSlot) == "number" then
				table.insert(lines, string.format("\t\tItemSlot = %d,", configData.ItemSlot))
			else
				table.insert(
					lines,
					string.format('\t\tItemSlot = "%s",', tostring(configData.ItemSlot):gsub('"', '\\"'))
				)
			end
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

	-- Backup every 5th generate. nah
	generateCount += 1
	local backupsFolder = ServerScriptService:FindFirstChild(BACKUPS_FOLDER_NAME)
	if not backupsFolder then
		backupsFolder = Instance.new("Folder")
		backupsFolder.Name = BACKUPS_FOLDER_NAME
		backupsFolder.Parent = ServerScriptService
	end

	-- Timestamp format: MMM DD HH:MM:SS
	local timestamp = os.date("%b %d %H:%M:%S")
	local backupModule = Instance.new("ModuleScript")
	backupModule.Name = timestamp
	backupModule.Source = finalSource
	backupModule.Parent = backupsFolder
	print("🗂️ Backup created:", BACKUPS_FOLDER_NAME .. "/" .. timestamp)
	-- createVisuals() -- Refresh visuals after saving
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
		if #masterItemConfigs > 0 then
			warn("MASTER ROOT ALREADY CREATED. PREVENT FROM CREATING A BROKEN LINK")
			return
		else
			rootConfig = {
				ItemId = rootId,
				Price = 40 + #masterItemConfigs * 5,
				Prefab = rootModel, -- Link the prefab
				DisplayName = rootId,
				UnlockedBy = nil,
			}
			table.insert(masterItemConfigs, rootConfig)
			existingItemIds[rootId] = true
		end
	end

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
				local ItemSlot = childModel:GetAttribute("ItemSlot")
				local childId = childModel.Name
				local uniqueChildId = childId
				-- Keep checking for a new ID as long as the current one exists
				while existingItemIds[uniqueChildId] do
					local newUID = generateUid()
					warn("Item", uniqueChildId, "already exist, changing to", newUID)
					uniqueChildId = newUID
				end

				local uniqueInFolder = workspace.Items.Value:FindFirstChild(uniqueChildId)
				while uniqueInFolder do
					local newUID = generateUid()
					warn("Item", uniqueChildId, "found in items folder, changing")
					uniqueChildId = newUID
					uniqueInFolder = workspace.Items.Value:FindFirstChild(uniqueChildId)
				end

				childModel.Name = uniqueChildId
				table.insert(rootConfig.Unlocks, uniqueChildId)

				local childConfig = {
					ItemId = uniqueChildId, -- Use the new unique ID
					Price = 40 + #masterItemConfigs * 5,
					Prefab = childModel, -- Link the prefab
					DisplayName = DisplayName, -- Use the new unique ID
					UnlockedBy = { rootId },
				}
				table.insert(masterItemConfigs, childConfig)
				childConfig.ItemSlot = ItemSlot
				-- Register the new unique ID so it's caught on the next loop
				existingItemIds[uniqueChildId] = true
				existingModels[childModel] = childConfig
			else
				local config = existingModels[childModel]
				if config.UnlockedBy and type(config.UnlockedBy) == "table" then
					table.insert(config.UnlockedBy, rootId)
				else
					config.UnlockedBy = { rootId }
				end
				table.insert(rootConfig.Unlocks, config.ItemId)
				warn("Model", childModel, "already being used, therefore rootConfig now is used to unlock this node.")
			end
		end
	end

	print("✅ Processed selection with root: " .. rootId)
	-- createVisuals() -- Refresh visuals after creating
	onGenerateModule()
end

local function itemSlotify()
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
	local configs
	local configModule = ServerScriptService:FindFirstChild(CONFIG_MODULE_NAME)
	if configModule then
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
			configs = result
			-- Populate the quick-lookup dictionary
			for _, config in ipairs(configs) do
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
			print("✅ Loaded " .. #configs .. " items from module.")
		else
			warn("⚠️ Failed to load or parse module. Starting fresh.", result)
		end
	else
		print("No config module found")
	end

	if configs then
		local count = 0
		for i, selected: Model in selection do
			for j, config in configs do
				if config.Prefab == selected then
					count += 1
					selected:SetAttribute("ItemSlot", count)
					config.ItemSlot = count
				end
			end
		end
		masterItemConfigs = configs
		onGenerateModule()
	end
end

local function DeSlotify()
	local selection = Selection:Get()
	for _, model: Model in ipairs(selection) do
		if model:GetAttribute("ItemSlot") ~= nil then
			model:SetAttribute("ItemSlot", nil)
		end
	end
	local configs
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
			configs = result
			-- Populate the quick-lookup dictionary
			for _, config in ipairs(configs) do
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
			print("✅ Loaded " .. #configs .. " items from module.")
		else
			warn("⚠️ Failed to load or parse module. Starting fresh.", result)
		end
	else
		print("No config module found")
	end

	if configs then
		local count = 0
		for i, selected: Model in selection do
			for j, config in configs do
				if config.Prefab == selected then
					selected:SetAttribute("ItemSlot", nil)
					config.ItemSlot = nil
				end
			end
		end
		masterItemConfigs = configs
		onGenerateModule()
	end
end

-- Add a UIListLayout to manage the sections automatically
local mainListLayout = Instance.new("UIListLayout")
mainListLayout.Parent = mainFrame
mainListLayout.FillDirection = Enum.FillDirection.Vertical
mainListLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainListLayout.Padding = UDim.new(0, 5)

-- ## --- Section: ItemSlot --- ##
local itemSlotSection = Instance.new("Frame")
itemSlotSection.Name = "ItemSlotSection"
itemSlotSection.Parent = mainFrame
itemSlotSection.BackgroundTransparency = 1
itemSlotSection.AutomaticSize = Enum.AutomaticSize.Y
itemSlotSection.Size = UDim2.new(1, 0, 0, 0)

local itemSlotLayout = Instance.new("UIListLayout")
itemSlotLayout.Parent = itemSlotSection
itemSlotLayout.FillDirection = Enum.FillDirection.Horizontal
itemSlotLayout.Padding = UDim.new(0, 5)

local itemSlotifyButton = Instance.new("TextButton")
itemSlotifyButton.Name = "ItemSlotifyButton"
itemSlotifyButton.Text = "ItemSlotify"
itemSlotifyButton.Parent = itemSlotSection
itemSlotifyButton.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
itemSlotifyButton.TextColor3 = Color3.new(1, 1, 1)
itemSlotifyButton.Font = Enum.Font.SourceSansBold
itemSlotifyButton.TextScaled = true
itemSlotifyButton.Size = UDim2.new(0.5, -5, 0, 32)
itemSlotifyButton.MouseButton1Click:Connect(itemSlotify)

local deSlotifyButton = Instance.new("TextButton")
deSlotifyButton.Name = "DeSlotifyButton"
deSlotifyButton.Text = "DeSlotify"
deSlotifyButton.Parent = itemSlotSection
deSlotifyButton.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
deSlotifyButton.TextColor3 = Color3.new(1, 1, 1)
deSlotifyButton.Font = Enum.Font.SourceSansBold
deSlotifyButton.TextScaled = true
deSlotifyButton.Size = UDim2.new(0.5, -5, 0, 32)
deSlotifyButton.MouseButton1Click:Connect(DeSlotify)

-- ## --- Section: Unlocks --- ##
local unlockSection = Instance.new("Frame")
unlockSection.Name = "UnlockSection"
unlockSection.Parent = mainFrame
unlockSection.BackgroundTransparency = 1
unlockSection.AutomaticSize = Enum.AutomaticSize.Y
unlockSection.Size = UDim2.new(1, 0, 0, 0)

local removeUnlockButton = Instance.new("TextButton")
removeUnlockButton.Name = "RemoveUnlockButton"
removeUnlockButton.Text = "Remove Unlock"
removeUnlockButton.Parent = unlockSection
removeUnlockButton.BackgroundColor3 = Color3.fromRGB(80, 80, 160)
removeUnlockButton.TextColor3 = Color3.new(1, 1, 1)
removeUnlockButton.Font = Enum.Font.SourceSansBold
removeUnlockButton.TextScaled = true
removeUnlockButton.Size = UDim2.new(1, 0, 0, 32)

-- ## --- Section: Display Name --- ##
local displayNameSection = Instance.new("Frame")
displayNameSection.Name = "DisplayNameSection"
displayNameSection.Parent = mainFrame
displayNameSection.BackgroundTransparency = 1
displayNameSection.AutomaticSize = Enum.AutomaticSize.Y
displayNameSection.Size = UDim2.new(1, 0, 0, 0)

local displayNameLayout = Instance.new("UIListLayout")
displayNameLayout.Parent = displayNameSection
displayNameLayout.FillDirection = Enum.FillDirection.Horizontal
displayNameLayout.Padding = UDim.new(0, 5)

local displayNameInput = Instance.new("TextBox")
displayNameInput.Name = "DisplayNameInput"
displayNameInput.Parent = displayNameSection
displayNameInput.PlaceholderText = "New Display Name"
displayNameInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
displayNameInput.TextColor3 = Color3.new(1, 1, 1)
displayNameInput.Font = Enum.Font.SourceSans
displayNameInput.TextScaled = true
displayNameInput.ClearTextOnFocus = false
displayNameInput.Size = UDim2.new(0.7, -5, 0, 32)

local setDisplayNameButton = Instance.new("TextButton")
setDisplayNameButton.Name = "SetDisplayNameButton"
setDisplayNameButton.Text = "Set Name"
setDisplayNameButton.Parent = displayNameSection
setDisplayNameButton.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
setDisplayNameButton.TextColor3 = Color3.new(1, 1, 1)
setDisplayNameButton.Font = Enum.Font.SourceSansBold
setDisplayNameButton.TextScaled = true
setDisplayNameButton.Size = UDim2.new(0.3, -5, 0, 32)

local function setDisplayName()
	local selection = Selection:Get()
	if #selection == 0 then
		warn("Please select at least one model.")
		return
	end

	local newName = displayNameInput.Text
	if not newName or newName == "" then
		warn("Display name cannot be empty.")
		return
	end

	local configs
	local configModule = ServerScriptService:FindFirstChild(CONFIG_MODULE_NAME)
	if configModule then
		local success, result = pcall(function()
			local tempModule = Instance.new("ModuleScript")
			tempModule.Source = configModule.Source
			tempModule.Parent = script
			local data = require(tempModule)
			tempModule:Destroy()
			return data
		end)
		if success and typeof(result) == "table" then
			configs = result
		else
			warn("⚠️ Failed to load or parse module.", result)
			return
		end
	else
		warn("No config module found")
		return
	end

	local configLookup: {} = {}
	for i, config in ipairs(configs) do
		configLookup[config.Prefab] = config
	end

	for _, item: Model in ipairs(selection) do
		if not item:IsA("Model") then
			continue
		end
		if not configLookup[item] then
			continue
		end
		item:SetAttribute("DisplayName", newName)
		configLookup[item].DisplayName = newName
	end
	masterItemConfigs = configs
	onGenerateModule()
end

setDisplayNameButton.MouseButton1Click:Connect(setDisplayName)

-- ## --- Section: Price Recalculation --- ##
local priceRecalcSection = Instance.new("Frame")
priceRecalcSection.Name = "PriceRecalcSection"
priceRecalcSection.Parent = mainFrame
priceRecalcSection.BackgroundTransparency = 1
priceRecalcSection.AutomaticSize = Enum.AutomaticSize.Y
priceRecalcSection.Size = UDim2.new(1, 0, 0, 0)

local priceRecalcLayout = Instance.new("UIListLayout")
priceRecalcLayout.Parent = priceRecalcSection
priceRecalcLayout.FillDirection = Enum.FillDirection.Horizontal
priceRecalcLayout.Padding = UDim.new(0, 5)

local multiplierInput = Instance.new("TextBox")
multiplierInput.Name = "MultiplierInput"
multiplierInput.Parent = priceRecalcSection
multiplierInput.Text = "1.12"
multiplierInput.PlaceholderText = "Multiplier (e.g., 1.12)"
multiplierInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
multiplierInput.TextColor3 = Color3.new(1, 1, 1)
multiplierInput.Font = Enum.Font.SourceSans
multiplierInput.TextScaled = true
multiplierInput.ClearTextOnFocus = false
multiplierInput.Size = UDim2.new(0.5, -5, 0, 32)

local recalcPricesButton = Instance.new("TextButton")
recalcPricesButton.Name = "RecalcPricesButton"
recalcPricesButton.Text = "Recalculate Prices"
recalcPricesButton.Parent = priceRecalcSection
recalcPricesButton.BackgroundColor3 = Color3.fromRGB(100, 80, 150)
recalcPricesButton.TextColor3 = Color3.new(1, 1, 1)
recalcPricesButton.Font = Enum.Font.SourceSansBold
recalcPricesButton.TextScaled = true
recalcPricesButton.Size = UDim2.new(0.5, -5, 0, 32)

local function recalculatePricesFromUI()
	local multiplier = tonumber(multiplierInput.Text)
	if not multiplier or multiplier <= 0 then
		warn("Invalid multiplier value. Please enter a positive number.")
		multiplierInput.Text = "1.12"
		return
	end

	local baseCost = 0 -- The cost of the second item (index 2)
	masterItemConfigs[1].Price = 0

	for i = 2, #masterItemConfigs do
		local itemconfig = masterItemConfigs[i]

		-- The new price is the baseCost multiplied by the multiplier,
		-- raised to the power of its position in the list.
		local itemtypecost = itemconfig.ItemSlot and 4 or 1
		baseCost += itemconfig.ItemSlot and 50 or 0
		itemconfig.Price = math.floor(
			(baseCost + itemtypecost > 1 and 50 or 0) * itemtypecost * (multiplier ^ math.floor((i - 2) / 5))
				+ 10 * (i - 2)
		)
	end

	onGenerateModule()
	print("✅ Prices recalculated with multiplier: " .. multiplier)
end

recalcPricesButton.MouseButton1Click:Connect(recalculatePricesFromUI)

-- Remove Unlock function and button
local function removeUnlock()
	local selection = Selection:Get()
	if #selection < 2 then
		warn("Select at least two models: first is the parent, rest are children to remove from unlocks.")
		return
	end
	local parentModel = selection[1]
	local parentConfig

	local configs
	local configModule = ServerScriptService:FindFirstChild(CONFIG_MODULE_NAME)
	if configModule then
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
			configs = result
			-- Populate the quick-lookup dictionary
			for _, config in ipairs(configs) do
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
			print("✅ Loaded " .. #configs .. " items from module.")
		else
			warn("⚠️ Failed to load or parse module. Starting fresh.", result)
		end
	else
		print("No config module found")
	end

	for _, config in ipairs(configs) do
		if config.Prefab == parentModel then
			parentConfig = config
			break
		end
	end
	if not parentConfig or not parentConfig.Unlocks then
		warn("First selected model has no unlocks.")
		return
	end

	for i = 2, #selection do
		local childModel = selection[i]
		local childConfig

		for _, config in ipairs(configs) do
			if config.Prefab == childModel then
				childConfig = config
				break
			end
		end
		if childConfig then
			-- Remove child from parent's Unlocks
			local idx = table.find(parentConfig.Unlocks, childConfig.ItemId)
			if idx then
				table.remove(parentConfig.Unlocks, idx)
			end
			-- Remove parent from child's UnlockedBy
			if childConfig.UnlockedBy then
				local idx2 = table.find(childConfig.UnlockedBy, parentConfig.ItemId)
				if idx2 then
					table.remove(childConfig.UnlockedBy, idx2)
				end
			end
		end
	end
	masterItemConfigs = configs
	onGenerateModule()
	-- createVisuals()
end

removeUnlockButton.MouseButton1Click:Connect(removeUnlock)

-- Connect button clicks to functions
-- Wrap relevant functions
createVisuals = ensureVisible(createVisuals)
destroyVisuals = ensureVisible(destroyVisuals)
onRefresh = ensureVisible(onRefresh)
onGenerateModule = ensureVisible(onGenerateModule)
onCreateFromSelection = ensureVisible(onCreateFromSelection)
recalculatePricesFromUI = ensureVisible(recalculatePricesFromUI)
generateBFSSortedModule = ensureVisible(generateBFSSortedModule)
generateDFSSortedModule = ensureVisible(generateDFSSortedModule)

refreshButton.Click:Connect(onRefresh)
createButton.Click:Connect(onCreateFromSelection)
generateButton.Click:Connect(onGenerateModule)
destroyvisualsButton.Click:Connect(destroyVisuals)
bfsSortButton.Click:Connect(generateBFSSortedModule)
dfsSortButton.Click:Connect(generateDFSSortedModule)
-- Handle plugin activation/deactivation
mainWidget.Changed:Connect(function(property)
	if property ~= "Enabled" then
		return
	end

	if mainWidget.Enabled then
		-- onRefresh()
	else
		destroyVisuals()
	end
end)

plugin.Unloading:Connect(function()
	destroyVisuals()
	local itemfolder = workspace.Items :: ObjectValue
	local OriginalBase = workspace.OriginalBase :: ObjectValue
	itemfolder.Value.Parent = game.ServerStorage
	OriginalBase.Value.Parent = game.ServerStorage
end)
