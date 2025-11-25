local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local ItemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)

type PlayerData = {
	Resources: { [string]: number },
	PlayerSettings: { MusicVolume: number },
	Progress: { EXP: number, LVL: number },
	Items: { { Item } },
	ItemSlots: { -- contains UID of items from PlayerData.Items
		{ [string]: string }
	},
}
type Item = {
	UID: string, --
	ItemId: string,
	DisplayName: string,
	Rate: number,
}

local function Inventory(props: {
	PlayerData: PlayerData?,
	onSellItem: ((itemUID: string) -> ())?,
	InventoryOpen: boolean?,
	close: () -> ()?,
	PlacedItemUids: { [string]: boolean }?,
})
	local PlayerData: PlayerData = props.PlayerData or {}
	local Items: { Item } = PlayerData.Items or {}
	local Phase: "opening" | "open" | "closing" | "closed", setPhase = React.useState("closed")
	local visible, setVisible = React.useState(Phase ~= "closed")
	local selected, setSelected = React.useState(nil)

	local children = {
		UIPadding = e("UIPadding", {
			-- PaddingTop = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 16),
		}),
		UIListLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalFlex = Enum.UIFlexAlignment.None,
			VerticalFlex = Enum.UIFlexAlignment.Fill,
			Padding = UDim.new(0, 8),
			VerticalAlignment = "Bottom",
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	local sell = function(tb: TextButton)
		local selectedItem = tb.Name
		if props.onSellItem then
			props.onSellItem(selectedItem)
		else
			-- Fallback to old behavior
			(game.ReplicatedStorage.Shared.Events.SellItem :: RemoteEvent):FireServer(selectedItem)
		end
	end
	local SFRef = React.useRef()
	local childNum = 0
	local function OnSelect(frame: Frame)
		setSelected(function(prev)
			if prev == frame.Name then
				return nil
			else
				return frame.Name
			end
		end)
	end
	local function OnDeselect(frame: Frame)
		setSelected(nil)
	end
	React.useEffect(function() end, { selected })
	-- Abstracted per-item UI component (see InventoryItem.lua)
	local InventoryItem = require(script.Parent.InventoryItem)

	-- Build a lookup table for item configs by ItemId
	local itemConfigLookup = {}
	for _, config in ipairs(ItemsConfig) do
		itemConfigLookup[config.ItemId] = config
	end

	for i, item in Items do
		if not item.UID then
			continue
		end
		childNum += 1

		-- Get item config similar to Shop
		local itemConfig = itemConfigLookup[item.ItemId]
		if not itemConfig then
			warn("No config found for item:", item.ItemId)
			continue
		end

		children[item.UID] = e(InventoryItem, {
			key = item.UID,
			UID = item.UID,
			Item = item,
			itemConfig = itemConfig,
			itemId = item.ItemId,
			index = i,
			Rate = item.Rate,
			LayoutOrder = i,
			Placed = props.PlacedItemUids[item.UID],
			Selected = selected,
			OnSelect = OnSelect,
			isMountedRef = props.isMountedRef,
			sell = sell,
		})
	end

	local animDur = 0.4
	local FrameRef = React.useRef()
	local tweenRef = React.useRef(nil)
	React.useEffect(function()
		local frame = FrameRef.current
		if not frame then
			return
		end

		-- Cancel previous tween if any
		if tweenRef.current then
			tweenRef.current:Cancel()
			tweenRef.current = nil
		end
	end, { props.InventoryOpen })

	return e("ImageLabel", {
		Size = UDim2.new(1, 0, 0, 240),
		Position = UDim2.new(0.5, 0, 1, 0), --CLOSED_POS,
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.new(0, 0.2, 0.2),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = false,
		Visible = props.InventoryOpen, -- visible,
		ref = FrameRef,
		ClipsDescendants = false,
		ZIndex = 1,
		Image = "rbxassetid://136242854116857",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(30, 30, 90, 90),
	}, {
		-- Title
		Title = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 40),
			AutomaticSize = Enum.AutomaticSize.XY,
			Position = UDim2.new(0.5, 0, 0, -40),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Font = "FredokaOne",
			TextSize = 32,
			Text = "🎒INVENTORY (" .. childNum .. "/" .. "24)",
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0,
			ZIndex = 2,
		}),

		UIGradient = e("UIGradient", {
			Color = ColorSequence.new(Color3.new(0.9, 0.6, 0.7), Color3.new(0.7, 0.5, 0.8)),
		}),
		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
		}),
		ScrollingFrame = e("ScrollingFrame", {
			ScrollingDirection = Enum.ScrollingDirection.X,
			Size = UDim2.new(1, 0, 1, -0),
			Position = UDim2.new(0, 0, 0, 0),
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			ref = SFRef,
			Active = false,
			ZIndex = 2,
			ClipsDescendants = true,
			ScrollBarThickness = 16,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
		}, children),
		CloseButton = e("TextButton", {
			-- AutomaticSize = Enum.AutomaticSize.XY,
			Size = UDim2.new(0, 42, 0, 42),
			BorderSizePixel = 0,
			Text = "X",
			Font = "FredokaOne",
			-- BackgroundTransparency = 0,
			-- BackgroundColor3 = Color3.new(1, 0.2, 0.4),
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 42,
			ZIndex = 10,
			[React.Event.Activated] = props.close,
			Position = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			Rounded = e(require(script.Parent.ui.rounded)),
		}),
	})
end

return Inventory
