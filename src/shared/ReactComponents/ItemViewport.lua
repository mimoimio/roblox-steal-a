local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useEffect = React.useEffect

type ItemViewportProps = {
	ItemId: string,
	Size: UDim2?,
	BackgroundTransparency: number?,
}

local function ItemViewport(props: ItemViewportProps)
	local viewportRef = React.useRef(nil)
	local modelRef = React.useRef(nil)
	local cameraRef = React.useRef(nil)

	useEffect(function()
		local viewport = viewportRef.current
		if not viewport then
			return
		end

		-- Create camera
		local camera = Instance.new("Camera")
		camera.Parent = viewport
		viewport.CurrentCamera = camera
		cameraRef.current = camera

		-- Try to find and clone the model
		local modelsFolder = game.ReplicatedStorage.Shared.Models
		local modelTemplate = modelsFolder:FindFirstChild(props.ItemId)

		if modelTemplate then
			local model = modelTemplate:Clone()
			model.Parent = viewport
			modelRef.current = model
			camera.CameraType = "Scriptable"

			-- Calculate the model's bounding box
			local cf, size = model:GetBoundingBox()

			-- Position camera 5 units away, looking at the center
			local maxSize = math.max(size.X, size.Y, size.Z)
			local distance = 3
			camera.CFrame = CFrame.new(cf.Position + Vector3.new(distance, distance, distance)) * CFrame.Angles(0, 0, 0)
			camera.CFrame = CFrame.lookAt(camera.CFrame.Position, cf.Position)
			camera.FieldOfView = 70
			camera:ZoomToExtents(model:GetBoundingBox())

			-- Adjust field of view to fit the model
		else
			warn("[ItemViewport] Model not found for ItemId:", props.ItemId)
		end

		-- Cleanup function
		return function()
			if modelRef.current then
				modelRef.current:Destroy()
				modelRef.current = nil
			end
			if cameraRef.current then
				cameraRef.current:Destroy()
				cameraRef.current = nil
			end
		end
	end, { props.ItemId })

	if props.children then
		props.children["rounded"] = e(require(script.Parent.ui.rounded))
	else
		props.children = {
			["rounded"] = e(require(script.Parent.ui.rounded)),
		}
	end
	return e("ViewportFrame", {
		Size = props.Size or UDim2.new(0.5, 0, 1, 0), --
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		BackgroundTransparency = props.BackgroundTransparency or 0,
		BackgroundColor3 = props.Color3 or Color3.new(0.2, 0.2, 0.4),
		Position = UDim2.new(0, 0, 0, 0),
		ref = viewportRef,
		ZIndex = props.ZIndex or 3,
	}, {
		props.children,
	})
end

return ItemViewport
