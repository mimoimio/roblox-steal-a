local React = require(game.ReplicatedStorage.Packages.react)
local e = React.createElement

local Item = require(script.Item)
local InventorySlots = require(script.InventorySlots)
local ShopSlots = require(script.ShopSlots)

function GetInventory()
	local inventory = (
		game.ReplicatedStorage.Shared:WaitForChild("Events"):WaitForChild("GetInventory") :: RemoteFunction
	):InvokeServer()
	warn("Invoked Inventory", inventory)
	return inventory
end

local function Inventory(props: {})
	local Items: { { DisplayName: string } }?, setItems = React.useState(nil)

	React.useEffect(function()
		setItems(GetInventory())
		warn("Doned")
	end, {})

	React.useEffect(function()
		warn(Items)
	end, { Items })

	-- Overlay first so we can pass ref during initial element creation
	local overlayRef = React.useRef(nil :: Frame?)
	-- Track slot instances via refs to get their AbsolutePosition/Size
	local slotRefs = React.useRef({} :: { [number]: Instance })

	-- Getter that computes centers from live refs
	local function getSlotCenters(): { Vector2 }
		local centers = {}
		for i = 1, #slotRefs.current do
			local slot = slotRefs.current[i]
			if slot and slot.AbsolutePosition and slot.AbsoluteSize then
				local pos = slot.AbsolutePosition
				local size = slot.AbsoluteSize
				centers[#centers + 1] = Vector2.new(pos.X + size.X / 2, pos.Y + size.Y / 2)
			end
		end
		return centers
	end
	local function getSlotCenterByIndex(index: number): Vector2?
		local slot = slotRefs.current[index]
		if slot and slot.AbsolutePosition and slot.AbsoluteSize then
			local pos = slot.AbsolutePosition
			local size = slot.AbsoluteSize
			return Vector2.new(pos.X + size.X / 2, pos.Y + size.Y / 2)
		end
		return nil
	end

	-- Drag end callback with occupancy check
	local SNAP_THRESHOLD = 100
	local function onItemDragEnd(homeIndex: number, pointer: Vector2): Vector2?
		local centers = getSlotCenters()
		if not centers or #centers == 0 then
			return nil
		end
		-- find nearest slot by pointer position
		local function nearest(point: Vector2)
			local minDist = math.huge
			local found
			for i, c in ipairs(centers) do
				local d = (point - c).Magnitude
				if d < minDist then
					minDist = d
					found = { index = i, pos = c, dist = d }
				end
			end
			return found
		end
		local n = nearest(pointer)
		if n and n.dist <= SNAP_THRESHOLD then
			-- Occupancy check: is there an item already at slot n.index?
			if Items then
				local occupied = false
				for i, _ in ipairs(Items) do
					if i ~= homeIndex then
						-- Treat array index as the item's current slot
						if i == n.index then
							occupied = true
							break
						end
					end
				end
				if not occupied then
					-- Move item within Items array to new index n.index
					setItems(function(prev)
						if not prev then
							return prev
						end
						local arr = table.clone(prev)
						-- Extract item at homeIndex
						local moving = arr[homeIndex]
						if not moving then
							return prev
						end
						table.remove(arr, homeIndex)
						-- Adjust insertion index if item removed before target
						local insertIndex = n.index
						if homeIndex < n.index then
							insertIndex -= 1
						end
						table.insert(arr, insertIndex, moving)
						return arr
					end)
					return n.pos
				end
			end
		end
		-- Revert to original home center
		return getSlotCenterByIndex(homeIndex)
	end

	local itemRenders = e(
		"Folder",
		{},
		(function()
			local children = {}
			for i, item in Items or {} do
				children["item" .. i] = e(Item, {
					getSlotCenters = getSlotCenters,
					getSlotCenterByIndex = getSlotCenterByIndex,
					overlayRef = overlayRef,
					homeIndex = i,
					Text = tostring(item.DisplayName),
					onDragEnd = onItemDragEnd,
				})
				warn(i)
			end
			warn(Items)
			return children
		end)()
	)

	-- Full-screen overlay for dragging (inactive, transparent)
	local children = {
		Overlay = e("Frame", {
			Name = "DragOverlay",
			ref = overlayRef,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Active = false,
			ZIndex = 10,
		}, {
			-- Render items directly under overlay so they are already in absolute space
			Items = itemRenders,
		}),
		Slots = e(InventorySlots, {
			slotRefs = slotRefs,
		}),
		ShopSlots = e(ShopSlots),
	}

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 0.9,
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 0,
	}, children)
end

return Inventory
