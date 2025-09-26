local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)

local App = require(game.ReplicatedStorage.Shared.ReactComponents.App)

function Mount()
	local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
	local ScreenGui = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
	ScreenGui.ResetOnSpawn = false
	local root = ReactRoblox.createRoot(ScreenGui)

	root:render(e(App))
end

Mount()
