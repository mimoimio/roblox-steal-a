local TiersConfig = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)
local textsize = require(script.Parent.textsize)
local React = require(game.ReplicatedStorage.Packages.React)
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local e = React.createElement
local useEffect = React.useEffect
local RunService = game:GetService("RunService")
local TS = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local useToast = require(game.ReplicatedStorage.Shared.ReactComponents.Toasts).useToast

local itemConfigs = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local variationConfigs = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
local tierConfigs = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)
local FormatItemLabelText = require(game.ReplicatedStorage.Shared.Utils.Format).FormatItemLabelText

type Item = {
	UID: string, --
	ItemId: string,
	DisplayName: string,
	Rate: number,
}
local DEFAULT_TWEEN = 0.25
local MOUNTED_SIZE = UDim2.new(1, 0, 1, 0)
local Size = MOUNTED_SIZE

local function ItemViewport(props)
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

	return e("ViewportFrame", {
		Size = UDim2.new(1, -16, 1, -16), --props.Size or
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		ref = viewportRef,
		ZIndex = props.ZIndex or 3,
	}, {
		rounded = e(require(script.Parent.ui.rounded)),
	})
end

local function PICell(props: {
	UID: string,
	Item: Item,
	LayoutOrder: number,
	clicked: () -> nil,
	Selected: boolean,
})
	local tooltipRef = React.useRef(nil)
	local resconnRef = React.useRef(nil)
	local mouseEnter, setMouseEnter = React.useState(false)
	local itemConfig = itemConfigs[props.Item.ItemId]
	local tier = itemConfig and tierConfigs[itemConfig.TierId]

	React.useEffect(function()
		-- Tooltip logic
		local tip = itemConfigs[props.Item.ItemId] and itemConfigs[props.Item.ItemId].ItemTip
		if not tip then
			return
		end
		if tooltipRef.current then
			tooltipRef.current:Destroy()
		end

		if mouseEnter then
			local gui: ScreenGui = game.ReplicatedStorage.Shared.HoverCard:Clone()
			gui.Card.Visible = false

			local pos = UserInputService:GetMouseLocation()
			gui.Card.ImageLabel.ItemTip.Text = tip
			tooltipRef.current = gui
			local fx, fy = pos.X + 12, pos.Y + 12
			gui.Card.Position = UDim2.new(0, fx, 0, fy)

			resconnRef.current = RunService.RenderStepped:Connect(function()
				gui.Parent = game.Players.LocalPlayer.PlayerGui
				pos = UserInputService:GetMouseLocation()

				fx, fy = pos.X + 12, pos.Y + 12
				local sizeX, sizeY = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
				local validX, validY = fx + gui.Card.AbsoluteSize.X < sizeX, fy + gui.Card.AbsoluteSize.Y < sizeY
				fx, fy = validX and fx or pos.X - 12, validY and fy or pos.Y - 12
				gui.Card.AnchorPoint = Vector2.new(validX and 0 or 1, validY and 0 or 1)
				gui.Card.Position = UDim2.new(0, fx, 0, fy)
				gui.Card.Visible = true
			end)
		end

		return function()
			if tooltipRef.current then
				tooltipRef.current:Destroy()
				tooltipRef.current = nil
			end
			if resconnRef.current then
				resconnRef.current:Disconnect()
				resconnRef.current = nil
			end
		end
	end, { mouseEnter })

	return e("TextButton", {
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.new(0, 150, 0, 150),
		ZIndex = 2,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Text = "",
		ref = function(textbutton: TextButton)
			if not textbutton then
				return
			end
			textbutton:SetAttribute("UID", props.UID)
		end,
		[React.Event.Activated] = props.clicked,
		[React.Event.MouseEnter] = itemConfig and itemConfig.ItemTip and function()
			setMouseEnter(true)
		end,
		[React.Event.MouseLeave] = itemConfig and itemConfig.ItemTip and function()
			setMouseEnter(false)
		end,
	}, {
		Color = tier and e("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1)),
			-- tier.ColorPrimary, tier.ColorSecondary or tier.ColorPrimary
			Rotation = 45,
		}),
		rounded = e(require(script.Parent.ui.rounded)),
		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 20),
		}),
		ItemImage = e(ItemViewport, {
			ItemId = props.Item.ItemId,
			BackgroundTransparency = 1,
			ZIndex = 3,
			Size = UDim2.new(1, 0, 1, 0),
			LayoutOrder = 1,
		}),
		bg = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0,
			ZIndex = 2,
			LayoutOrder = 2,
		}, {
			Rounded = e(require(script.Parent.ui.rounded)),
			Color = e("UIGradient", {
				Color = props.Placed and ColorSequence.new(Color3.new(0, 1, 0.2), Color3.new(0, 0.6, 0.4))
					or ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.6, 0.7, 0.8)),
				Rotation = 45,
			}),
		}),
		ItemName = e("TextLabel", {
			TextStrokeTransparency = 0,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = "FredokaOne",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 0),
			RichText = true,
			Position = UDim2.new(0, 0, 0, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Text = (
				(props.Item.Entered and "" or "*")
				.. (itemConfig.DisplayName or props.itemId)
				.. "\n"
				.. "<font size='14'>"
				.. TiersConfig[itemConfig.TierId].DisplayName
				.. "</font>"
			),
			TextColor3 = TiersConfig[itemConfig.TierId].ColorPrimary or Color3.new(1, 1, 1),
			TextWrapped = true,
			ZIndex = 4,
		}, {
			UITextSizeConstraint = e(textsize, { Min = 14, Max = 16 }),
		}),
		RateLabel = e("TextLabel", {
			BackgroundTransparency = 1,
			TextStrokeTransparency = 0,
			LayoutOrder = 0,
			Position = UDim2.new(0, 0, 1, 0),
			AnchorPoint = Vector2.new(0, 0),
			Size = UDim2.new(1, 0, 0, 0),
			Font = "FredokaOne",
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = "Rate: " .. Alyanum.new(props.Rate or 0):toString() .. "/s",
			TextColor3 = Color3.fromRGB(100, 255, 100),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 4,
		}, {
			UITextSizeConstraint = e(textsize, { Min = 12, Max = 12 }),
		}),
	})
end

return PICell
