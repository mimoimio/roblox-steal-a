local ServerScriptService = game:GetService("ServerScriptService")
local React = require(script.Parent.Packages.React)
local ItemListUI = require(script.Parent.ItemListUI)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

-- Constants for our plugin's assets
local CONFIG_MODULE_NAME = "GeneratedItemConfigs"
local VISUALS_FOLDER_NAME = "TycoonTreeVisuals"
local DISPLAY_NAME_ATTRIBUTE = "DisplayName" -- Constant for the attribute name

-- Tries to load and parse the existing ModuleScript
local function getConfigModule()
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
			return result
		else
			task.spawn(function()
				error(result)
			end)
		end

		-- if success and typeof(result) == "table" then
		-- 	masterItemConfigs = result
		-- 	-- Populate the quick-lookup dictionary
		-- 	for _, config in ipairs(masterItemConfigs) do
		-- 		existingItemIds[config.ItemId] = true
		-- 		-- *** ADDITION: Ensure DisplayName attribute exists on load ***
		-- 		if config.Prefab and config.Prefab:IsA("Instance") and config.Prefab.Parent then
		-- 			-- Use the helper function to check/set the attribute
		-- 			-- We prioritize the DisplayName saved in the config, but fallback to ItemId
		-- 			local expectedDisplayName = config.DisplayName or config.ItemId
		-- 			getOrSetDisplayName(config.Prefab, expectedDisplayName)
		-- 		else
		-- 			warn(
		-- 				"Could not validate DisplayName attribute for "
		-- 					.. config.ItemId
		-- 					.. " - Prefab missing or invalid."
		-- 			)
		-- 		end
		-- 	end
		-- 	print("✅ Loaded " .. #masterItemConfigs .. " items from module.")
		-- else
		-- 	warn("⚠️ Failed to load or parse module. Starting fresh.", result)
		-- end
	else
		print("🌳 No config module found. Starting a new tree.")
	end
end

local function App(props: { refreshButton: PluginToolbarButton })
	local MasterItemConfig, setMasterItemConfig = useState(getConfigModule())
	local mainWidgetEnabled, setMainWidgetEnabled = useState(props.mainWidget.Enabled)

	useEffect(function()
		-- warn("props.refreshButton", props.refreshButton)
		local connections = {
			refreshButton = props.refreshButton.Click:Connect(function()
				setMasterItemConfig(getConfigModule())
			end),
			props.mainWidget.Changed:Connect(function(property)
				if property ~= "Enabled" then
					return
				end
				setMainWidgetEnabled(props.mainWidget[property])
			end),
		}
		return function()
			for i, conn in connections do
				conn:Discnnect()
			end
		end
	end, { props.refreshButton })

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(136, 169, 241),
	}, mainWidgetEnabled and {
		ItemListUI = e(ItemListUI, {
			MasterItemConfig = MasterItemConfig,
			UIPadding = e("UIPadding", {
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
			}),
		}),
	} or {})
end

return App
