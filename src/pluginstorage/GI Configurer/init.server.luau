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
local masterGIModuleScripts = {}
local function refresh()
	local GIVisualsFolder = workspace:FindFirstChild("GIVisualsFolder") or Instance.new("Folder", workspace)
	GIVisualsFolder.Name = "GIVisualsFolder"
	local GIGUIVisualsFolder = StarterGui:FindFirstChild("GIGUIVisualsFolder") or Instance.new("Folder", StarterGui)
	GIGUIVisualsFolder.Name = "GIGUIVisualsFolder"
	local ItemsConfigFolder = ReplicatedStorage.Shared.Configs.ItemsConfig

	GIVisualsFolder:ClearAllChildren()
	GIGUIVisualsFolder:ClearAllChildren()

	masterGIModuleScripts = {}
	masterGIConfigs = {}
	for i, d: ModuleScript in ItemsConfigFolder:GetDescendants() do
		if not d:IsA("ModuleScript") then
			continue
		end

		-- local clonedModule = d:Clone()
		local success, config = pcall(function()
			return require(d)
		end)
		if not success then
			warn("Error", config)
		end

		table.insert(masterGIConfigs, config)
		masterGIModuleScripts[config] = d
	end
	table.sort(masterGIConfigs, function(a, b)
		return a.Price > b.Price
	end)
	for i, config in masterGIConfigs do
		local prefab = ReplicatedStorage.Shared.Models:FindFirstChild(config.ItemId)
			or ReplicatedStorage.Shared.Models:FindFirstChild("error")
		local model = prefab:Clone() :: Model
		model.Parent = GIVisualsFolder
		model:PivotTo(CFrame.new(0, 40, 10 * i))
		local bbAtt = (script.Attachment :: Attachment):Clone()
		bbAtt.Parent = model
		local bb = bbAtt.BillboardGui
		bb.Parent = GIGUIVisualsFolder
		bb.Adornee = bbAtt
		bb.Price.Text = Alyanum.new(config.Price):toString()
		bb.DisplayName.Text = tostring(config.DisplayName)
		bb.ItemId.Text = tostring(config.ItemId)
		bb.Rate.Text = Alyanum.new(config.Rate):toString();

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

			-- Get the original module script
			local originalModule = masterGIModuleScripts[config]

			-- Parse the source to replace the Price value
			local source = originalModule.Source
			local newSource = source:gsub("Price%s*=%s*%d+", "Price = " .. num)

			-- Create a new module script with updated source
			local newModule = originalModule:Clone()
			newModule.Source = newSource

			-- Replace in the configs folder
			originalModule.Parent = nil
			newModule.Parent = ItemsConfigFolder
			newModule.Name = originalModule.Name

			-- Update the reference
			masterGIModuleScripts[config] = newModule

			-- Clean up
			originalModule:Destroy()

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

			-- Get the original module script
			local originalModule = masterGIModuleScripts[config]

			-- Parse the source to replace the Rate value
			local source = originalModule.Source
			local newSource = source:gsub("Rate%s*=%s*%d+", "Rate = " .. num)

			-- Create a new module script with updated source
			local newModule = originalModule:Clone()
			newModule.Source = newSource

			-- Replace in the configs folder
			originalModule.Parent = nil
			newModule.Parent = ItemsConfigFolder
			newModule.Name = originalModule.Name

			-- Update the reference
			masterGIModuleScripts[config] = newModule

			-- Clean up
			originalModule:Destroy()

			refresh()
			warn(string.format("Updated %s Rate to %d", config.ItemId, num))
		end)
	end
	warn("final masterGIConfigs", masterGIConfigs)
end

refreshButton.Click:Connect(refresh)
