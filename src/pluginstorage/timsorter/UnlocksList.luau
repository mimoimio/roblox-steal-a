--[[
	UnlocksList Component
	Renders a list of unlocks with UIListLayout
]]

local React = require(script.Parent.Packages.React)
local e = React.createElement
local useRef = React.useRef

local UnlockedItem = require(script.Parent.UnlockedItem)

type UnlocksListProps = {
	unlocks: { string },
	configLookup: { [string]: any },
	selectedUnlockIndex: number?,
	onSelectUnlock: (index: number?) -> (),
	onMoveUp: () -> (),
	onMoveDown: () -> (),
	onGoToItem: (itemId: string) -> (),
	onFocusItem: (itemId: string) -> (),
}

local function UnlocksList(props: UnlocksListProps)
	local scrollingFrameRef = useRef()

	local children = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	-- Add each unlock item to the children dictionary
	for index, unlockId in ipairs(props.unlocks) do
		local unlockConfig = props.configLookup[unlockId]
		local isSelected = props.selectedUnlockIndex == index
		local unlockCount = unlockConfig and unlockConfig.Unlocks and #unlockConfig.Unlocks or 0
		local displayName = unlockConfig and (unlockConfig.DisplayName or unlockConfig.ItemId) or unlockId

		children["Unlock_" .. index] = e(UnlockedItem, {
			unlockId = unlockId,
			ItemSlot = unlockConfig and unlockConfig.ItemSlot,
			displayName = string.format(
				"%s (%d)%s",
				displayName,
				unlockCount,
				unlockConfig and unlockConfig.ItemSlot and " [ITEM SLOT]" or ""
			),
			index = index,
			isSelected = isSelected,
			onSelect = function()
				props.onSelectUnlock(isSelected and nil or index)
			end,
			onMoveUp = props.onMoveUp,
			onMoveDown = props.onMoveDown,
			onGoTo = function()
				-- Reset canvas position to top
				if scrollingFrameRef.current then
					scrollingFrameRef.current.CanvasPosition = Vector2.new(0, 0)
				end
				props.onGoToItem(unlockId)
			end,
			onFocus = function()
				props.onFocusItem(unlockId)
			end,
			canMoveUp = isSelected and index > 1,
			canMoveDown = isSelected and index < #props.unlocks,
		})
	end

	return e("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 6,
		ref = scrollingFrameRef,
	}, children)
end

return UnlocksList
