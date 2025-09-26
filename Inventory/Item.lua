local React = require(game.ReplicatedStorage.Packages.react)
local e = React.createElement
local ITEM_SIZE = Vector2.new(80, 80)

local function getNearestSlot(pos, slotPositions)
	local minDist, nearest = math.huge, nil
	for i, slotPos in ipairs(slotPositions) do
		local dist = (pos - slotPos).Magnitude
		if dist < minDist then
			minDist = dist
			nearest = { index = i, pos = slotPos, dist = dist }
		end
	end
	warn(nearest)
	return nearest
end

-- Clean Item component (defined once, outside getNearestSlot)
local function Item(props)
	local draggedPos, setDraggedPos = React.useState(nil :: UDim2?)
	local pointerOffset = React.useRef(Vector2.new())
	local frameRef = React.useRef(nil :: Frame?)

	React.useEffect(function()
		local frame = frameRef.current
		if not frame or not props.overlayRef or not props.overlayRef.current or not props.getSlotCenterByIndex then
			return
		end
		local center = props.getSlotCenterByIndex(props.homeIndex)
		if not center then
			return
		end
		frame.Parent = props.overlayRef.current
		frame.Size = UDim2.fromOffset(ITEM_SIZE.X, ITEM_SIZE.Y)
		local topLeft = center - ITEM_SIZE / 2
		setDraggedPos(UDim2.fromOffset(topLeft.X, topLeft.Y))
	end, {})

	return e("TextLabel", {
		ref = frameRef,
		Size = UDim2.fromOffset(ITEM_SIZE.X, ITEM_SIZE.Y),
		-- AnchorPoint = -Vector2.new(0.5, 0.5),
		BackgroundTransparency = 0.3,
		Position = draggedPos or UDim2.new(0, 0, 0, 0),
		ZIndex = 25,
		Active = false,
		Text = props.Text,
	}, {
		DragDetector = e("UIDragDetector", {
			[React.Event.DragStart] = function(_, input: Vector2)
				local frame = frameRef.current
				if not frame then
					return
				end
				local absPos = frame.AbsolutePosition
				pointerOffset.current = input - Vector2.new(absPos.X, absPos.Y)
			end,
			[React.Event.DragContinue] = function(_, input: Vector2)
				if input then
					setDraggedPos(
						UDim2.fromOffset(input.X - pointerOffset.current.X, input.Y - pointerOffset.current.Y)
					)
				end
			end,
			[React.Event.DragEnd] = function(_: Frame, input: Vector2)
				if not input or not props.getSlotCenters or not props.getSlotCenterByIndex then
					return
				end
				local centers = props.getSlotCenters()
				local nearest = getNearestSlot(_.Parent.AbsolutePosition + ITEM_SIZE / 2, centers)
				local targetCenter
				if nearest and nearest.dist <= 100 then
					targetCenter = nearest.pos
				else
					targetCenter = props.getSlotCenterByIndex(--[[prev index or ]] props.homeIndex)
				end
				if targetCenter then
					local topLeft = targetCenter - ITEM_SIZE / 2
					setDraggedPos(UDim2.fromOffset(topLeft.X, topLeft.Y))
				end
			end,
		}),
	})
end
return Item
