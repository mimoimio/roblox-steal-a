local UserInputService = game:GetService("UserInputService")
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)

local App = require(game.ReplicatedStorage.Shared.ReactComponents.App)

for i, d: Instance in game.ReplicatedStorage.Shared.ReactComponents:GetDescendants() do
	pcall(function()
		require(d)
	end)
end

local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()

local ScreenGui2 = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
ScreenGui2.ResetOnSpawn = false
ScreenGui2.Name = "ReactRoot2"
ScreenGui2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local root2 = ReactRoblox.createRoot(ScreenGui2)

function restart() -- every 60 seconds
	local ScreenGui = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Name = "ReactRoot"
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local root = ReactRoblox.createRoot(ScreenGui)
	root:render(e(App))
	-- task.delay(4, function()
	-- 	root:unmount()
	-- 	restart()
	-- end)
end
task.spawn(function()
	restart()
end)
-- local useEffect = React.useEffect
-- local useState = React.useState
-- local app2 = function(props)
-- 	local panel, setPanel = useState("none")

-- 	local function toggle(panel)
-- 		setPanel(function(prev)
-- 			if prev == panel then
-- 				return "none"
-- 			else
-- 				return panel
-- 			end
-- 		end)
-- 	end

-- 	useEffect(function()
-- 		local conn = UserInputService.InputBegan:Connect(function(io, gp)
-- 			if io.KeyCode == Enum.KeyCode.E then
-- 				toggle("inventory")
-- 			elseif io.KeyCode == Enum.KeyCode.C then
-- 				toggle("settings")
-- 			end
-- 		end)
-- 		return function()
-- 			conn:Disconnect()
-- 		end
-- 	end, {})

-- 	useEffect(function()
-- 		warn("panel", panel)
-- 	end, { panel })
-- 	return e("Frame", {
-- 		Size = UDim2.new(1, 0, 1, 0),
-- 		BackgroundTransparency = 1,
-- 	}, {
-- 		list = e(require(game.ReplicatedStorage.Shared.ReactComponents.ui.verticallist)),
-- 		InventoryButton = e("TextButton", {
-- 			BackgroundColor3 = panel == "inventory" and Color3.new(0, 1, 0) or Color3.new(1, 0, 0),
-- 			AutomaticSize = Enum.AutomaticSize.XY,
-- 			Text = "Inventory",
-- 			-- [React.Event.Activated] = toggle("inventory"),
-- 		}),
-- 		SettingsButton = e("TextButton", {
-- 			BackgroundColor3 = panel == "settings" and Color3.new(0, 1, 0) or Color3.new(1, 0, 0),
-- 			AutomaticSize = Enum.AutomaticSize.XY,
-- 			Text = "Settings",
-- 			-- [React.Event.Activated] = toggle("settings"),
-- 		}),
-- 	})
-- end
-- root2:render(e(app2))
