--[[
	Tycoon Tree Builder Plugin v2
	- React
]]

local React = require(script.Packages.React)
local App = require(script.App)
local e = React.createElement
local ReactRoblox = require(script.Packages.ReactRoblox)
local Alyanum = require(script.Packages.Alyanum)

-- Plugin UI
local mainWidget = plugin:CreateDockWidgetPluginGui(
	"TycoonTreeBuilder",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, true, false, 300, 400, 250, 300)
)
mainWidget.Title = "Tycoon Tree Builder v3"
mainWidget.Enabled = false

local toolbar = plugin:CreateToolbar("Tycoon Tree Builder v3")
local refreshButton = toolbar:CreateButton("Refresh", "Load/Refresh from the config module", "rbxassetid://8508980527")
local toggleButton = toolbar:CreateButton("Toggle UI", "Show/Hide the plugin UI", "rbxassetid://8508980527")
-- local createButton = toolbar:CreateButton("Create", "Create configs from selection", "rbxassetid://109251559")
-- local generateButton = toolbar:CreateButton("Complete", "Save changes to the ModuleScript", "rbxassetid://732391129")

local root = ReactRoblox.createRoot(mainWidget)
root:render(e(App, {
	refreshButton = refreshButton,
	mainWidget = mainWidget,
}))

toggleButton.Click:Connect(function()
	mainWidget.Enabled = not mainWidget.Enabled
end)
