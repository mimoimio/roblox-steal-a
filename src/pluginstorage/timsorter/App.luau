--[[
	TimSorter App Component
	Sorts unlocks within a selected item config
]]

local React = require(script.Parent.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

type ItemConfig = {
	ItemId: string,
	DisplayName: string?,
	Price: number,
	Unlocks: { string }?,
	UnlockedBy: { string }?,
	Prefab: string?,
	ItemSlot: number?,
}

type AppProps = {
	configModule: ModuleScript?,
	onSave: (configs: { ItemConfig }) -> (),
}

local UnlockedItem = require(script.Parent.UnlockedItem)
local UnlocksList = require(script.Parent.UnlocksList)
local Visualizer = require(script.Parent.Visualizer)

local function App(props: AppProps)
	local configs: { ItemConfig }, setConfigs = useState({})
	local configLookup: { [string]: ItemConfig }, setConfigLookup = useState({})
	local selectedItemId: string?, setSelectedItemId = useState(nil)
	local selectedUnlockIndex: number?, setSelectedUnlockIndex = useState(nil)
	local visualsEnabled: boolean, setVisualsEnabled = useState(false)

	-- Load configs from module
	useEffect(function()
		if not props.configModule then
			return
		end
		warn(props.configModule, "configmodule useEffect done")

		local success, result = pcall(function()
			-- Create a temporary module to bypass the cache
			local tempModule = Instance.new("ModuleScript")
			tempModule.Source = props.configModule.Source
			tempModule.Parent = script -- Parent to plugin script
			local data = require(tempModule)
			tempModule:Destroy()
			return data
		end)

		if success and typeof(result) == "table" then
			warn("result", result)
			setConfigs(result)

			-- Build lookup table
			local lookup = {}
			for _, config in ipairs(result) do
				lookup[config.ItemId] = config
			end
			setConfigLookup(lookup)

			-- Auto-select first item if none selected
			if #result > 0 and not selectedItemId then
				setSelectedItemId(result[1].ItemId)
			end
		else
			warn("Failed to load configs:", result)
		end
	end, { props.configModule })

	-- Get selected config
	local selectedConfig = selectedItemId and configLookup[selectedItemId] or nil
	local unlocks = selectedConfig and selectedConfig.Unlocks or {}

	-- Navigation handlers
	local function goToPrevious()
		if not selectedItemId then
			return
		end
		for i, config in ipairs(configs) do
			if config.ItemId == selectedItemId and i > 1 then
				setSelectedItemId(configs[i - 1].ItemId)
				setSelectedUnlockIndex(nil)
				break
			end
		end
	end

	local function goToNext()
		if not selectedItemId then
			return
		end
		for i, config in ipairs(configs) do
			if config.ItemId == selectedItemId and i < #configs then
				setSelectedItemId(configs[i + 1].ItemId)
				setSelectedUnlockIndex(nil)
				break
			end
		end
	end

	-- Reorder unlock handlers
	local function moveUnlockUp()
		if not selectedConfig or not selectedUnlockIndex or selectedUnlockIndex <= 1 then
			return
		end

		setConfigs(function(prevConfigs)
			local newConfigs = table.clone(prevConfigs)
			for i, config in ipairs(newConfigs) do
				if config.ItemId == selectedItemId then
					local newUnlocks = table.clone(config.Unlocks or {})
					-- Swap with previous
					newUnlocks[selectedUnlockIndex], newUnlocks[selectedUnlockIndex - 1] =
						newUnlocks[selectedUnlockIndex - 1], newUnlocks[selectedUnlockIndex]
					newConfigs[i] = table.clone(config)
					newConfigs[i].Unlocks = newUnlocks
					break
				end
			end

			-- Rebuild lookup table with new configs
			local newLookup = {}
			for _, cfg in ipairs(newConfigs) do
				newLookup[cfg.ItemId] = cfg
			end
			setConfigLookup(newLookup)

			return newConfigs
		end)

		setSelectedUnlockIndex(selectedUnlockIndex - 1)
	end

	local function moveUnlockDown()
		if not selectedConfig or not selectedUnlockIndex or selectedUnlockIndex >= #unlocks then
			return
		end

		setConfigs(function(prevConfigs)
			local newConfigs = table.clone(prevConfigs)
			for i, config in ipairs(newConfigs) do
				if config.ItemId == selectedItemId then
					local newUnlocks = table.clone(config.Unlocks or {})
					-- Swap with next
					newUnlocks[selectedUnlockIndex], newUnlocks[selectedUnlockIndex + 1] =
						newUnlocks[selectedUnlockIndex + 1], newUnlocks[selectedUnlockIndex]
					newConfigs[i] = table.clone(config)
					newConfigs[i].Unlocks = newUnlocks
					break
				end
			end

			-- Rebuild lookup table with new configs
			local newLookup = {}
			for _, cfg in ipairs(newConfigs) do
				newLookup[cfg.ItemId] = cfg
			end
			setConfigLookup(newLookup)

			return newConfigs
		end)

		setSelectedUnlockIndex(selectedUnlockIndex + 1)
	end

	-- Save handler
	local function handleSave()
		props.onSave(configs)
	end

	-- Go to item handler
	local function goToItem(itemId: string)
		setSelectedItemId(itemId)
		setSelectedUnlockIndex(nil)
	end

	-- Focus camera on item handler
	local function focusOnItem(itemId: string)
		local config = configLookup[itemId]
		if not config or not config.Prefab then
			return
		end

		local model: Model = config.Prefab

		if model then
			local boxCFrame, boxSize = model:GetBoundingBox()

			local camera = workspace.CurrentCamera
			camera.CameraType = Enum.CameraType.Scriptable
			local targetPos = boxCFrame.Position
			local offset = camera.CFrame.LookVector * 10
			camera.CFrame = CFrame.new(targetPos - offset, targetPos)
			camera.Focus = CFrame.new(targetPos)

			local Selection = game:GetService("Selection")
			Selection:Set({ model })
			camera.CameraType = Enum.CameraType.Custom
		end
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(45, 45, 45),
		BorderSizePixel = 0,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),

		-- Toggle Visuals Button
		ToggleVisualsButton = e("TextButton", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = visualsEnabled and Color3.fromRGB(100, 60, 120) or Color3.fromRGB(60, 60, 80),
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.SourceSansBold,
			TextSize = 18,
			Text = visualsEnabled and "👁️ Hide Visuals" or "👁️ Show Visuals",
			LayoutOrder = 1,
			[React.Event.Activated] = function()
				setVisualsEnabled(not visualsEnabled)
			end,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		}),

		-- Save Button
		SaveButton = e("TextButton", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = Color3.fromRGB(60, 120, 60),
			TextColor3 = Color3.new(1, 1, 1),
			Font = Enum.Font.SourceSansBold,
			TextSize = 18,
			Text = "💾 Save Changes",
			LayoutOrder = 2,
			[React.Event.Activated] = handleSave,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		}),

		-- Visualizer Component
		Visualizer = e(Visualizer, {
			enabled = visualsEnabled,
			selectedConfig = selectedConfig,
			configLookup = configLookup,
			selectedUnlockIndex = selectedUnlockIndex,
			onSelectUnlock = setSelectedUnlockIndex,
			onNavigatePrevious = goToPrevious,
			onNavigateNext = goToNext,
			onGoToItem = goToItem,
		}),

		-- Selected Item Frame
		SelectedItemFrame = selectedConfig
				and e("Frame", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Color3.fromRGB(35, 35, 35),
					BorderSizePixel = 0,
					LayoutOrder = 2,
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),

					Layout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						Padding = UDim.new(0, 6),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),

					Padding = e("UIPadding", {
						PaddingTop = UDim.new(0, 8),
						PaddingBottom = UDim.new(0, 8),
						PaddingLeft = UDim.new(0, 8),
						PaddingRight = UDim.new(0, 8),
					}),

					-- Navigation Row
					NavRow = e("Frame", {
						Size = UDim2.new(1, 0, 0, 30),
						BackgroundTransparency = 1,
						LayoutOrder = 1,
					}, {
						Layout = e("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							Padding = UDim.new(0, 4),
							VerticalAlignment = Enum.VerticalAlignment.Center,
						}),

						PrevButton = e("TextButton", {
							Size = UDim2.new(0, 60, 0, 30),
							BackgroundColor3 = Color3.fromRGB(80, 80, 80),
							TextColor3 = Color3.new(1, 1, 1),
							Font = Enum.Font.SourceSansBold,
							TextSize = 16,
							Text = "← Prev",
							[React.Event.Activated] = goToPrevious,
						}, {
							Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
						}),

						NextButton = e("TextButton", {
							Size = UDim2.new(0, 60, 0, 30),
							BackgroundColor3 = Color3.fromRGB(80, 80, 80),
							TextColor3 = Color3.new(1, 1, 1),
							Font = Enum.Font.SourceSansBold,
							TextSize = 16,
							Text = "Next →",
							[React.Event.Activated] = goToNext,
						}, {
							Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
						}),
					}),

					-- Item Info
					ItemIdLabel = e("TextLabel", {
						Size = UDim2.new(1, 0, 0, 20),
						BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(200, 200, 200),
						Font = Enum.Font.SourceSansBold,
						TextSize = 14,
						Text = "ItemId: " .. selectedConfig.ItemId,
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 2,
					}),

					DisplayNameLabel = e("TextLabel", {
						Size = UDim2.new(1, 0, 0, 20),
						BackgroundTransparency = 1,
						TextColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.SourceSansBold,
						TextSize = 16,
						Text = "Name: " .. (selectedConfig.DisplayName or selectedConfig.ItemId),
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 3,
					}),

					PriceLabel = e("TextLabel", {
						Size = UDim2.new(1, 0, 0, 20),
						BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(100, 200, 100),
						Font = Enum.Font.SourceSans,
						TextSize = 14,
						Text = "Price: $" .. selectedConfig.Price,
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 4,
					}),

					-- UnlockedBy Section
					UnlockedBySection = (selectedConfig.UnlockedBy and #selectedConfig.UnlockedBy > 0)
							and e(
								"Frame",
								{
									Size = UDim2.new(1, 0, 0, 0),
									AutomaticSize = Enum.AutomaticSize.Y,
									BackgroundTransparency = 1,
									LayoutOrder = 5,
								},
								(function()
									local unlockedByChildren = {
										Layout = e("UIListLayout", {
											FillDirection = Enum.FillDirection.Vertical,
											Padding = UDim.new(0, 4),
											SortOrder = Enum.SortOrder.LayoutOrder,
										}),

										Header = e("TextLabel", {
											Size = UDim2.new(1, 0, 0, 25),
											BackgroundTransparency = 1,
											TextColor3 = Color3.fromRGB(255, 150, 150),
											Font = Enum.Font.SourceSansBold,
											TextSize = 15,
											Text = "Unlocked By (" .. #selectedConfig.UnlockedBy .. "):",
											TextXAlignment = Enum.TextXAlignment.Left,
											LayoutOrder = 1,
										}),
									}

									-- Add buttons for each UnlockedBy item
									for i, parentId in ipairs(selectedConfig.UnlockedBy) do
										local parentConfig = configLookup[parentId]
										local displayName = parentConfig
												and (parentConfig.DisplayName or parentConfig.ItemId)
											or parentId

										unlockedByChildren["Parent_" .. i] = e("TextButton", {
											Size = UDim2.new(1, 0, 0, 30),
											BackgroundColor3 = Color3.fromRGB(60, 60, 60),
											TextColor3 = Color3.new(1, 1, 1),
											Font = Enum.Font.SourceSans,
											TextSize = 14,
											Text = "→ " .. displayName,
											TextXAlignment = Enum.TextXAlignment.Left,
											LayoutOrder = i + 1,
											[React.Event.Activated] = function()
												goToItem(parentId)
											end,
										}, {
											Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
											Padding = e("UIPadding", {
												PaddingLeft = UDim.new(0, 8),
												PaddingRight = UDim.new(0, 8),
											}),
										})
									end

									return unlockedByChildren
								end)()
							)
						or nil,

					-- Unlocks Header
					UnlocksHeader = e("TextLabel", {
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(150, 150, 255),
						Font = Enum.Font.SourceSansBold,
						TextSize = 15,
						Text = "Unlocks (" .. #unlocks .. "):",
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 6,
					}), -- Unlocks List
					UnlocksList = #unlocks > 0 and e(UnlocksList, {
						unlocks = unlocks,
						configLookup = configLookup,
						selectedUnlockIndex = selectedUnlockIndex,
						onSelectUnlock = setSelectedUnlockIndex,
						onMoveUp = moveUnlockUp,
						onMoveDown = moveUnlockDown,
						onGoToItem = goToItem,
						onFocusItem = focusOnItem,
					}) or nil,
				})
			or e("TextLabel", {
				Size = UDim2.new(1, 0, 1, -48),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(150, 150, 150),
				Font = Enum.Font.SourceSansItalic,
				TextSize = 16,
				Text = "No item selected",
				LayoutOrder = 2,
			}),
	})
end

return App
