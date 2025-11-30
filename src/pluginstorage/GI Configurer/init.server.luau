local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Alyanum = require(script.Packages.Alyanum)

local GIConfig = plugin:CreateToolbar("Gen Items Config")
local refreshButton = GIConfig:CreateButton("Refresh", "Refresh.", "rbxassetid://7276907613")
local destroyvisualsButton = GIConfig:CreateButton("Hide", "Hide.", "rbxassetid://7276907613")

destroyvisualsButton.Click:Connect(function()
	local GIVisualsFolder = workspace:FindFirstChild("GIVisualsFolder") or Instance.new("Folder", workspace)
	GIVisualsFolder.Name = "GIVisualsFolder"
	GIVisualsFolder:ClearAllChildren()
	local GIGUIVisualsFolder = StarterGui:FindFirstChild("GIGUIVisualsFolder") or Instance.new("Folder", StarterGui)
	GIGUIVisualsFolder.Name = "GIGUIVisualsFolder"
	GIGUIVisualsFolder:ClearAllChildren()
end)

local masterGIConfigs = {}

local function generateRawConfigsSource(configs)
	local lines = {
		'local isserver = game:GetService("RunService"):IsServer()',
		"local EffectHelpers",
		"if isserver then",
		'\tEffectHelpers = require(game:GetService("ServerScriptService").Server.Utils.EffectHelpers)',
		"end",
		"local sharedtypes = require(game.ReplicatedStorage.Shared.types)",
		"type ItemConfig = sharedtypes.ItemConfig",
		"",
		"return {",
	}

	for i, config in ipairs(configs) do
		-- Add comment with item name
		table.insert(lines, "\t-- " .. (config.ItemId or "unknown"))
		table.insert(lines, "\t{")

		-- ItemId
		if config.ItemId then
			table.insert(lines, string.format('\t\tItemId = "%s",', config.ItemId))
		end

		-- DisplayName
		if config.DisplayName then
			table.insert(lines, string.format('\t\tDisplayName = "%s",', config.DisplayName))
		end

		-- Rate
		if config.Rate then
			table.insert(lines, string.format("\t\tRate = %s,", tostring(config.Rate)))
		end

		-- Price
		if config.Price then
			table.insert(lines, string.format("\t\tPrice = %s,", tostring(config.Price)))
		end

		-- TierId
		if config.TierId then
			table.insert(lines, string.format('\t\tTierId = "%s",', config.TierId))
		end

		-- Variations
		if config.Variations then
			local varList = {}
			for _, v in ipairs(config.Variations) do
				table.insert(varList, string.format('"%s"', v))
			end
			table.insert(lines, string.format("\t\tVariations = { %s },", table.concat(varList, ", ")))
		end

		-- Growth function
		if config.Growth and config.Growth ~= "" then
			table.insert(lines, string.format("\t\tGrowth = [[%s]],", config.Growth))
		end

		-- Entry function
		if config.Entry and config.Entry ~= "" then
			table.insert(lines, string.format("\t\tEntry = [[%s]],", config.Entry))
		end

		-- Removed function
		if config.Removed and config.Removed ~= "" then
			table.insert(lines, string.format("\t\tRemoved = [[%s]],", config.Removed))
		end

		-- ItemTip
		if config.ItemTip and config.ItemTip ~= "" then
			table.insert(lines, string.format("\t\tItemTip = [[%s]],", config.ItemTip))
		end

		table.insert(lines, "\t},")
	end

	table.insert(lines, "}")
	table.insert(lines, "")

	return table.concat(lines, "\n")
end

local function saveRawConfigsModule(configs)
	local targetPath = ReplicatedStorage.Shared.Configs.ItemsConfig
	local oldModule = targetPath:FindFirstChild("RawConfigs")

	-- Create backup with timestamp
	if oldModule then
		local timestamp = os.date("%Y%m%d_%H%M%S")
		local backup = oldModule:Clone()
		backup.Name = "RawConfigs_backup_" .. timestamp
		backup.Parent = targetPath
		warn("Created backup: " .. backup.Name)

		-- Destroy old module
		oldModule:Destroy()
	end

	-- Generate new source
	local newSource = generateRawConfigsSource(configs)

	-- Create new module
	local newModule = Instance.new("ModuleScript")
	newModule.Name = "RawConfigs"
	newModule.Source = newSource
	newModule.Parent = targetPath
	warn(newModule)

	warn("Saved new RawConfigs module with " .. #configs .. " items")
	return newModule
end

local function refresh()
	masterGIConfigs = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig.RawConfigs)
	local GIVisualsFolder = workspace:FindFirstChild("GIVisualsFolder") or Instance.new("Folder", workspace)
	GIVisualsFolder.Name = "GIVisualsFolder"
	local GIGUIVisualsFolder = StarterGui:FindFirstChild("GIGUIVisualsFolder") or Instance.new("Folder", StarterGui)
	GIGUIVisualsFolder.Name = "GIGUIVisualsFolder"

	GIVisualsFolder:ClearAllChildren()
	GIGUIVisualsFolder:ClearAllChildren()

	table.sort(masterGIConfigs, function(a, b)
		return a.Price > b.Price
	end)
	for i, config in masterGIConfigs do
		local prefab = ReplicatedStorage.Shared.Models:FindFirstChild(config.ItemId)
			or ReplicatedStorage.Shared.Models:FindFirstChild("error")
		local model = prefab:Clone() :: Model
		model.Parent = GIVisualsFolder
		model:PivotTo(CFrame.new(0, 40, 10 * i))

		--[[ Simple Attributes]]
		local bbAtt = (script.Attachment :: Attachment):Clone()
		bbAtt.Parent = model
		local bb = bbAtt.BillboardGui
		bb.Parent = GIGUIVisualsFolder
		bb.Adornee = bbAtt
		bb.Price.Text = Alyanum.new(config.Price):toString()
		bb.DisplayName.Text = tostring(config.DisplayName)
		bb.ItemId.Text = tostring(config.ItemId)
		bb.Rate.Text = Alyanum.new(config.Rate):toString()
		bb.Rate.Text = Alyanum.new(config.Rate):toString()

		local funcBB = script.Attachment:WaitForChild("Function"):Clone()
		funcBB.Parent = GIGUIVisualsFolder
		funcBB.Adornee = bbAtt
		local funcTextBox = funcBB.TextBoxRef.Value

		local effect = Instance.new("StringValue", model)
		funcBB.Frame.Entry.Activated:Connect(function()
			effect.Value = "Entry"
		end)
		funcBB.Frame.Growth.Activated:Connect(function()
			effect.Value = "Growth"
		end)
		funcBB.Frame.Removed.Activated:Connect(function()
			effect.Value = "Removed"
		end)
		funcBB.Frame.ItemTip.Activated:Connect(function()
			effect.Value = "ItemTip"
		end)
		funcBB.Frame.FlashEffect.Activated:Connect(function()
			effect.Value = "FlashEffect"
		end)
		funcBB.Frame.SAVE.Activated:Connect(function()
			saveRawConfigsModule(masterGIConfigs)
			refresh()
		end);
		(funcTextBox :: TextBox).Changed:Connect(function(property)
			if property == "Text" then
				config[effect.Value] = funcTextBox[property]
			end
		end)
		effect.Changed:Connect(function(value)
			funcTextBox.Text = config[value] or ""
			(funcTextBox :: TextBox).PlaceholderText = value
			funcBB.Frame.Entry.BackgroundColor3 = value == "Entry" and Color3.new(1, 0, 0) or Color3.new(0.5, 0.5, 0.5)
			funcBB.Frame.Growth.BackgroundColor3 = value == "Growth" and Color3.new(1, 0, 0)
				or Color3.new(0.5, 0.5, 0.5)
			funcBB.Frame.Removed.BackgroundColor3 = value == "Removed" and Color3.new(1, 0, 0)
				or Color3.new(0.5, 0.5, 0.5)
			funcBB.Frame.ItemTip.BackgroundColor3 = value == "ItemTip" and Color3.new(1, 0, 0)
				or Color3.new(0.5, 0.5, 0.5)
			funcBB.Frame.FlashEffect.BackgroundColor3 = value == "FlashEffect" and Color3.new(1, 0, 0)
				or Color3.new(0.5, 0.5, 0.5)
		end)
		effect.Value = config.Entry and "Entry" or config.Growth and "Growth" or "Removed"
		funcTextBox.Text = config[effect.Value] or ""
		local ctrl = Instance.new("BoolValue", model);
		-- (funcTextBox :: TextBox).Changed:Connect(function(property)
		-- 	warn(property, funcTextBox[property])
		-- end);
		-- (funcTextBox :: TextBox).InputBegan:Connect(function(io)
		-- 	warn(io.KeyCode, ctrl.Value)
		-- 	if io.KeyCode == Enum.KeyCode.LeftControl then
		-- 		ctrl.Value = true
		-- 	elseif io.KeyCode == Enum.KeyCode.Return then
		-- 		(funcTextBox :: TextBox):ReleaseFocus()
		-- 		warn(funcTextBox.Text)
		-- 		config[effect.Value] = funcTextBox.Text
		-- 	end
		-- end);
		-- (funcTextBox :: TextBox).InputEnded:Connect(function(io)
		-- 	if io.KeyCode == Enum.KeyCode.LeftControl then
		-- 		ctrl.Value = false
		-- 	end
		-- end);

		(bb.Price :: TextBox).FocusLost:Connect(function(enterpressed)
			if not enterpressed then
				return
			end
			local num = tonumber(bb.Price.Text)
			if not num then
				return
			end

			-- Update the config's Price
			config.Price = num

			-- Save and refresh
			saveRawConfigsModule(masterGIConfigs)
			refresh()
			warn(string.format("Updated %s Price to %d", config.ItemId, num))
		end);

		(bb.Rate :: TextBox).FocusLost:Connect(function(enterpressed)
			if not enterpressed then
				return
			end
			local num = tonumber(bb.Rate.Text)
			if not num then
				return
			end

			-- Update the config's Rate
			config.Rate = num

			-- Save and refresh
			saveRawConfigsModule(masterGIConfigs)
			refresh()
			warn(string.format("Updated %s Rate to %d", config.ItemId, num))
		end)
	end
	warn("final masterGIConfigs", masterGIConfigs)
end

refreshButton.Click:Connect(refresh)
--  game.DataStoreService:GetDataStore("Player"):RemoveAsync(5470482596)
