local Alyanum = require(script.Parent.Packages.Alyanum)
local React = require(script.Parent.Packages.React)
local e = React.createElement

local function ItemVisualizer(props: {
	itemConfig: {},
	i: number,
})
	local children = {
		UIListLayout = e("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalFlex = "Fill",
		}),
		TextStrokeColor3 = Color3.new(0, 0, 0),
		UIPadding = e("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}),
	}
	return e("TextLabel", {
		Text = ([[%5s) %20s: %-8s]]):format(
			tostring(props.i),
			props.itemConfig.DisplayName,
			Alyanum.new(props.itemConfig.Price):toString()
		),
		Font = Enum.Font.RobotoMono,
		BackgroundTransparency = 0.9,
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 16,
		LayoutOrder = props.i,
		TextXAlignment = "Left",
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Color3.new(0, 0, 0),
	}, children)
end

return ItemVisualizer

-- if configData.Prefab then
-- 	local model: Model = configData.Prefab
-- 	if model then
-- 		local attachToPart = Instance.new("Part", visualsFolder) --model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
-- 		local thisBox, thisSize = model:GetBoundingBox()
-- 		attachToPart:PivotTo(thisBox)
-- 		attachToPart.Size = Vector3.one * 0.01
-- 		attachToPart.Transparency = 1
-- 		attachToPart.Locked = true
-- 		attachToPart.CanQuery = false
-- 		attachToPart.CanTouch = false
-- 		attachToPart.CanCollide = false

-- 		if attachToPart then
-- 			local index = i
-- 			-- Create the attachment for the beam
-- 			local att = Instance.new("Attachment", attachToPart)
-- 			table.insert(existingVisuals, att)
-- 			attachments[configData.ItemId] = att

-- 			-- Create the BillboardGui indicator
-- 			local billboard = Instance.new("BillboardGui", game:GetService("StarterGui")) --
-- 			table.insert(existingVisuals, billboard)
-- 			billboard.Name = "ItemIndicator"
-- 			billboard.Size = UDim2.fromScale(2, 1)
-- 			billboard.AlwaysOnTop = true
-- 			billboard.LightInfluence = 0
-- 			billboard.Adornee = attachToPart
-- 			billboard.Active = true
-- 			billboard.SizeOffset = Vector2.new(0.5, 0)

-- 			local nameBox = Instance.new("TextBox", billboard)
-- 			nameBox.Size = UDim2.new(1, 0, 0.3, 0)
-- 			nameBox.Text = configData.ItemId
-- 			nameBox.BackgroundTransparency = 0.5
-- 			nameBox.BackgroundColor3 = Color3.new(0, 0, 0)
-- 			nameBox.TextColor3 = Color3.new(1, 1, 1)
-- 			nameBox.LayoutOrder = 1
-- 			nameBox.FocusLost:Connect(function(enterpressed)
-- 				local name: string = tostring(nameBox.Text)
-- 				if not name or name:len() == 0 then
-- 					nameBox.Text = configData.ItemId
-- 					return
-- 				end
-- 				local alreadyused
-- 				for j, itemconfig in masterItemConfigs do
-- 					alreadyused = itemconfig.ItemId == name
-- 					if alreadyused then
-- 						break
-- 					end
-- 				end
-- 				if alreadyused then
-- 					warn("NAME ALREADY BEING USED")
-- 					nameBox.Text = configData.ItemId
-- 					return
-- 				end

-- 				for j, itemconfig in masterItemConfigs do
-- 					if not itemconfig.Unlocks or type(itemconfig.Unlocks) ~= "table" then
-- 						continue
-- 					end
-- 					local foundat = table.find(itemconfig.Unlocks, configData.Prefab.Name)
-- 					if foundat then
-- 						itemconfig.Unlocks[foundat] = name
-- 					end
-- 				end
-- 				configData.ItemId = name
-- 				configData.Prefab.Name = name
-- 				onGenerateModule()
-- 			end)

-- 			local label = Instance.new("TextBox", billboard)
-- 			label.Size = UDim2.new(1, 0, 0.3, 0)
-- 			-- *** CHANGE: Use DisplayName here ***
-- 			label.Text = configData.DisplayName or "**" .. configData.ItemId -- Fallback just in case
-- 			label.BackgroundTransparency = 0.5
-- 			label.BackgroundColor3 = Color3.new(0, 0, 0)
-- 			label.LayoutOrder = 3
-- 			label.TextColor3 = Color3.new(1, 1, 1)
-- 			label.FocusLost:Connect(function(enterpressed)
-- 				local name: string = tostring(label.Text)
-- 				if not name or name:len() == 0 or name == "" then
-- 					nameBox.Text = configData.DisplayName or "**" .. configData.ItemId -- Fallback just in case
-- 					return
-- 				end
-- 				configData.DisplayName = name
-- 				model:SetAttribute(DISPLAY_NAME_ATTRIBUTE, name)

-- 				onGenerateModule()
-- 			end)
-- 			-- Previous button
-- 			local prevButton = Instance.new("TextButton", nameBox)
-- 			prevButton.Size = UDim2.new(0, 30, 1, 0)
-- 			prevButton.Position = UDim2.new(0, 0, 0, 0)
-- 			prevButton.AnchorPoint = Vector2.new(0, 0)
-- 			prevButton.Text = "<"
-- 			prevButton.BackgroundTransparency = 0.3
-- 			prevButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
-- 			prevButton.TextColor3 = Color3.new(1, 1, 1)
-- 			prevButton.Font = Enum.Font.SourceSansBold
-- 			prevButton.TextSize = 18
-- 			prevButton.Activated:Connect(function()
-- 				local prevIndex = i - 1
-- 				if prevIndex >= 1 and masterItemConfigs[prevIndex] and masterItemConfigs[prevIndex].Prefab then
-- 					local prevModel: Model = masterItemConfigs[prevIndex].Prefab
-- 					local prevPart = prevModel.PrimaryPart or prevModel:FindFirstChildWhichIsA("BasePart", true)
-- 					local prevBoxCFrame, prevBoxSize = prevModel:GetBoundingBox()
-- 					if prevPart then
-- 						local camera = workspace.CurrentCamera
-- 						camera.CameraType = Enum.CameraType.Scriptable
-- 						local targetPos = prevBoxCFrame.Position
-- 						local offset = camera.CFrame.LookVector * 5 --[[+ 0.1 * prevBoxSize.Magnitude]]
-- 						camera.CFrame = CFrame.new(targetPos - offset, targetPos)
-- 						camera.Focus = CFrame.new(targetPos)
-- 						Selection:Set({ prevModel })
-- 						camera.CameraType = Enum.CameraType.Custom
-- 					end
-- 				end
-- 			end)

-- 			-- Next button
-- 			local nextButton = Instance.new("TextButton", nameBox)
-- 			nextButton.Size = UDim2.new(0, 30, 1, 0)
-- 			nextButton.Position = UDim2.new(1, 0, 0, 0)
-- 			nextButton.AnchorPoint = Vector2.new(1, 0)
-- 			nextButton.Text = ">"
-- 			nextButton.BackgroundTransparency = 0.3
-- 			nextButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
-- 			nextButton.TextColor3 = Color3.new(1, 1, 1)
-- 			nextButton.Font = Enum.Font.SourceSansBold
-- 			nextButton.TextSize = 18
-- 			nextButton.Activated:Connect(function()
-- 				local nextIndex = i + 1
-- 				if
-- 					nextIndex <= #masterItemConfigs
-- 					and masterItemConfigs[nextIndex]
-- 					and masterItemConfigs[nextIndex].Prefab
-- 				then
-- 					local nextModel: Model = masterItemConfigs[nextIndex].Prefab
-- 					local nextPart = nextModel.PrimaryPart or nextModel:FindFirstChildWhichIsA("BasePart", true)
-- 					local nextBoxCFrame, nextBoxSize = nextModel:GetBoundingBox()
-- 					if nextPart then
-- 						local camera = workspace.CurrentCamera
-- 						camera.CameraType = Enum.CameraType.Scriptable
-- 						local targetPos = nextBoxCFrame.Position
-- 						local offset = camera.CFrame.LookVector * 5 --[[+ 0.1 * prevBoxSize.Magnitude]]
-- 						camera.CFrame = CFrame.new(targetPos - offset, targetPos)
-- 						camera.Focus = CFrame.new(targetPos)
-- 						Selection:Set({ nextModel })
-- 						camera.CameraType = Enum.CameraType.Custom
-- 					end
-- 				end
-- 			end)

-- 			local PriceBox = Instance.new("TextBox", billboard)
-- 			PriceBox.TextEditable = true
-- 			PriceBox.Size = UDim2.new(1, 0, 0.3, 0)
-- 			PriceBox.Text = configData.Price
-- 			PriceBox.BackgroundTransparency = 0.5
-- 			PriceBox.BackgroundColor3 = Color3.new(0, 0, 0)
-- 			PriceBox.TextColor3 = Color3.new(1, 1, 1)
-- 			PriceBox.FocusLost:Connect(function(enterpressed)
-- 				local num = tonumber(PriceBox.Text)
-- 				if not num then
-- 					PriceBox.Text = configData.Price
-- 					return
-- 				end
-- 				configData.Price = num
-- 				onGenerateModule()
-- 			end)
-- 			PriceBox.LayoutOrder = 2

-- 			local deletebutton = Instance.new("TextButton", PriceBox)
-- 			deletebutton.Size = UDim2.new(0, 30, 1, 0)
-- 			deletebutton.AnchorPoint = Vector2.new(1, 0)
-- 			deletebutton.Position = UDim2.new(1, 0, 0, 0)
-- 			deletebutton.Text = "Dlt"
-- 			deletebutton.BackgroundTransparency = 0.5
-- 			deletebutton.BackgroundColor3 = Color3.new(1, 0, 0)
-- 			deletebutton.TextColor3 = Color3.new(1, 1, 1)
-- 			deletebutton.Activated:Connect(function(inputObject, clickCount)
-- 				local thisConfig = table.remove(masterItemConfigs, i)

-- 				for j, itemconfig in masterItemConfigs do
-- 					if not itemconfig.Unlocks or type(itemconfig.Unlocks) ~= "table" then
-- 						continue
-- 					end
-- 					local foundat = table.find(itemconfig.Unlocks, thisConfig.Prefab.Name)
-- 					if foundat then
-- 						table.remove(itemconfig.Unlocks, foundat)
-- 					end
-- 				end
-- 				onGenerateModule()
-- 			end)

-- 			local NumberBox = Instance.new("TextBox", PriceBox)
-- 			NumberBox.TextEditable = true
-- 			NumberBox.Size = UDim2.new(0, 30, 1, 0)
-- 			NumberBox.Text = index
-- 			NumberBox.BackgroundTransparency = 0.5
-- 			NumberBox.BackgroundColor3 = Color3.new(0, 0, 0)
-- 			NumberBox.TextColor3 = Color3.new(1, 1, 1)
-- 			NumberBox.FocusLost:Connect(function(enterpressed)
-- 				local num = tonumber(NumberBox.Text)
-- 				if not num then
-- 					NumberBox.Text = index
-- 					return
-- 				end

-- 				local currentIndex = index
-- 				local targetIndex = num
-- 				if targetIndex <= 0 or targetIndex >= #masterItemConfigs then
-- 					warn("Outside of total indexes!")
-- 					NumberBox.Text = index
-- 					return
-- 				end
-- 				if targetIndex == 1 or currentIndex == 1 then
-- 					warn("PREVENT CHANGING ON ROOT ITEMS")
-- 					NumberBox.Text = index
-- 					return
-- 				end
-- 				if masterItemConfigs[targetIndex].Unlocks or masterItemConfigs[currentIndex].Unlocks then
-- 					warn("PREVENT CHANGING ON UNLOCKS ITEM")
-- 					NumberBox.Text = index
-- 					return
-- 				end

-- 				-- if the target is bigger, simply swap from current to the target
-- 				if targetIndex > currentIndex then
-- 					local tempConfig = masterItemConfigs[targetIndex]
-- 					masterItemConfigs[targetIndex] = masterItemConfigs[currentIndex]
-- 					masterItemConfigs[currentIndex] = tempConfig

-- 				-- if target is smaller, remove current, and insert at target, therefore pushing forward the rest
-- 				elseif targetIndex < currentIndex then
-- 					local itemToMove = table.remove(masterItemConfigs, currentIndex)
-- 					table.insert(masterItemConfigs, targetIndex, itemToMove)
-- 					index = targetIndex
-- 				else -- currentindex == targetindex
-- 					return
-- 				end
-- 				onGenerateModule()
-- 			end)

-- 			local UIListLayout = Instance.new("UIListLayout", billboard)
-- 			UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- 			local button = workspace.Button.Value:Clone()
-- 			table.insert(existingVisuals, button)
-- 			button:PivotTo(configData.Prefab:GetPivot())
-- 			button.Parent = visualsFolder
-- 			button.PrimaryPart.BillboardGui.TextLabel.Text = configData.DisplayName or configData.ItemId
-- 			button.Changed:Connect(function(property)
-- 				--warn(property, button[property])
-- 				if property ~= "WorldPivot" then
-- 					return
-- 				end
-- 				warn("done")
-- 				configData.Prefab.WorldPivot = button[property]
-- 			end)
-- 		else
-- 			warn("NO BASEPART IN THE MODEL", model)
-- 		end
-- 	end
-- end
