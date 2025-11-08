local Players = game:GetService("Players")

local tool = script.Parent
if not tool or not tool:IsA("Tool") then
	-- If script isn't parented to a Tool, bail early
	return
end

local player = Players.LocalPlayer
if not player then
	return
end

local PlayerGui = player:WaitForChild("PlayerGui")

-- Require React and ReactRoblox from ReplicatedStorage.Packages
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)

-- Crosshair component (returns a Frame centered on screen)
local function Crosshair()
	return e("Frame", {
		Name = "WandCrosshair",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0.5, 0.5, 0),
		Size = UDim2.new(0, 48, 0, 48),
		BackgroundTransparency = 1,
	}, {
		Vertical = e("Frame", {
			Name = "Vertical",
			Size = UDim2.new(0, 2, 0, 24),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}),
		Horizontal = e("Frame", {
			Name = "Horizontal",
			Size = UDim2.new(0, 24, 0, 2),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}),
		CenterDot = e("Frame", {
			Name = "CenterDot",
			Size = UDim2.new(0, 4, 0, 4),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}),
	})
end

-- State for mounted root and ScreenGui
local root = nil
local screenGui = nil

local function mountCrosshair()
	if root then
		return
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WandCrosshairGui"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = PlayerGui

	root = ReactRoblox.createRoot(screenGui)
	root:render(e(Crosshair))
end

local function unmountCrosshair()
	if root then
		-- Try unmounting the React root first
		if typeof(root.unmount) == "function" then
			pcall(function()
				root:unmount()
			end)
		else
			pcall(function()
				root:render(nil)
			end)
		end
		root = nil
	end

	if screenGui and screenGui.Parent then
		screenGui:Destroy()
		screenGui = nil
	end
end

local zoom
local iszoomedin
-- Connect tool events
tool.Equipped:Connect(function()
	-- Enable crosshair when tool is equipped
	mountCrosshair()
	-- Lock camera to first person while equipped
	iszoomedin = player.CameraMode == Enum.CameraMode.LockFirstPerson
	warn(player.CameraMode)
	zoom = (workspace.CurrentCamera:GetPivot().Position - player.Character:GetPivot().Position).Magnitude
	pcall(function()
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end)
end)

tool.Unequipped:Connect(function()
	-- Disable crosshair when tool is unequipped
	unmountCrosshair()
	-- Restore camera mode to Classic when unequipped
	if not iszoomedin then
		player.CameraMinZoomDistance = zoom
		task.delay(0.4, function()
			player.CameraMinZoomDistance = 0
		end)
		pcall(function()
			player.CameraMode = Enum.CameraMode.Classic
		end)
		zoom = nil
		iszoomedin = nil
	end
end)

-- Add test behavior on activation: spawn a physics part propelled in the camera look direction
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local function onActivated()
	local camera = Workspace.CurrentCamera
	if not camera then
		camera = Workspace:FindFirstChild("Camera") or Workspace:WaitForChild("CurrentCamera")
	end
	if not camera then
		return
	end

	local look = camera.CFrame.LookVector
	local pos = camera.CFrame.Position + look * 2

	local part = Instance.new("Part")
	part.Size = Vector3.new(0.4, 0.4, 0.4)
	part.CFrame = CFrame.new(pos)
	part.Anchored = false
	part.CanCollide = false
	part.Shape = Enum.PartType.Ball
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 200, 50)
	part.Parent = Workspace

	-- Give it an initial linear velocity in the look direction
	local SPEED = 100
	if not pcall(function()
		part.AssemblyLinearVelocity = look * SPEED
	end) then
		-- Fallback for older engines: use :SetNetworkOwner or apply BodyVelocity
		local bv = Instance.new("BodyVelocity")
		bv.Velocity = look * SPEED
		bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		bv.P = 1e4
		bv.Parent = part
		Debris:AddItem(bv, 0.5)
	end

	Debris:AddItem(part, 5)
end

tool.Activated:Connect(onActivated)
-- Cleanup if the script is disabled/destroyed
script.AncestryChanged:Connect(function()
	if not script:IsDescendantOf(game) then
		unmountCrosshair()
	end
end)

return nil
