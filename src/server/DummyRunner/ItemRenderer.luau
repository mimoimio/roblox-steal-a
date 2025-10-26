local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState
local useRef = React.useRef

local Dummies = require(script.Parent.Dummies)
local ICDummies = Dummies.ItemConfigs
local PDDummy = Dummies.PlayerData

local function Item(props: {
	Owned: boolean,
	ItemId: string,
	RootArea: Part,
	BuyButton: (ItemId: string) -> nil,
})
	useEffect(function()
		local button: Model, model: Model
		if props.Owned then
			model = Dummies:GetModelFromItemId(props.ItemId)

			local cf = props.RootArea
				:GetPivot()
				:ToWorldSpace(workspace.OriginalBase.RootArea:GetPivot():ToObjectSpace(model:GetPivot()))
			model:PivotTo(cf)
			model.Parent = workspace
			game.ReplicatedStorage.Shared.Events.Ping:FireAllClients()
		else
			model = Dummies:GetModelFromItemId(props.ItemId)
			button = Dummies:GetButton()
			local originalBoundingCF = model:GetBoundingBox()
			local boundingCFrame = props.RootArea:GetPivot():ToWorldSpace(
				workspace.OriginalBase.RootArea:GetPivot():ToObjectSpace(originalBoundingCF)
			)
			local cf = props.RootArea
				:GetPivot()
				:ToWorldSpace(workspace.OriginalBase.RootArea:GetPivot():ToObjectSpace(model:GetPivot()))
			button:PivotTo(cf)
			button.Parent = workspace;
			(button.PrimaryPart.BillboardGui.TextLabel :: TextLabel).Text = (props.DisplayName or props.ItemId)
				.. "-[$"
				.. props.Price
				.. "]"
			local touched = false
			button.PrimaryPart.Touched:Connect(function(part: Part)
				if part.Name ~= "HumanoidRootPart" and part.Parent:FindFirstChild("Humanoid") then
					return
				end

				if not props.BuyButton(props.ItemId) then
					return
				end
				local Debris = game:GetService("Debris")
				local pemitter = (function()
					local clone = workspace.ParticlePart:Clone()
					clone:PivotTo(cf)
					clone.Parent = workspace
					return clone
				end)()
				Debris:AddItem(pemitter, 3)

				--[[ Create temporary beam between model pivot and bounding box center]]
				local tempPart = Instance.new("Part")
				tempPart.Transparency = 1
				tempPart.Anchored = true
				tempPart.CanCollide = false
				tempPart.Size = Vector3.new(0.1, 0.1, 0.1)
				tempPart.Parent = workspace
				Debris:AddItem(tempPart, 3)

				local att0 = Instance.new("Attachment")
				att0.WorldPosition = cf.Position
				att0.Parent = tempPart

				local att1 = Instance.new("Attachment")
				att1.WorldPosition = boundingCFrame.Position
				att1.Parent = tempPart

				local beam = Instance.new("Beam")
				beam.Attachment0 = att0
				beam.Attachment1 = att1
				beam.Width0 = 1
				beam.Width1 = 1
				beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
				beam.FaceCamera = true
				beam.Parent = tempPart
				beam.Texture = "rbxassetid://136242854116857"
				beam.TextureSpeed = 0.4
				beam.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0.4),
					NumberSequenceKeypoint.new(1, 1),
				})

				warn(tempPart)

				task.wait(1 / 10)
				pemitter.ParticleEmitter:Emit()
			end)
		end
		return function()
			if model then
				model:Destroy()
			end
			if button then
				button:Destroy()
			end
		end
	end, { props.Owned })
	return e("Folder")
end

local function ItemRenderer()
	local players, setPlayers = useState(nil)
	local CashIntances, setCashIntances = useState(nil)
	local cash, setCash = useState(PDDummy.Cash)

	local PlayerData, setPlayerData = useState(PDDummy)
	local children = {}

	useEffect(function()
		game.Players.PlayerAdded:Connect(function(player)
			setPlayers(game.Players:GetPlayers())
		end)
		task.spawn(function()
			while task.wait(1) do
				PDDummy.Cash += PDDummy.Rate
				setCash(PDDummy.Cash)
			end
		end)
	end, {})

	useEffect(function()
		local CashIntancesx = {}
		for i, player in players or {} do
			local leaderstats = player:FindFirstChild("leaderstats")
				or (function()
					local folder = Instance.new("Folder", player)
					folder.Name = "leaderstats"
					return folder
				end)()

			local Cash = leaderstats:FindFirstChild("Cash")
				or ({
					pcall(function()
						local cashValue = Instance.new("IntValue", leaderstats)
						cashValue.Name = "Cash"
						return cashValue
					end),
				})[2]
			table.insert(CashIntancesx, Cash)
		end
		warn("CashIntancesx", CashIntancesx)
		setCashIntances(CashIntancesx)
		return function()
			for i, cashx in CashIntancesx do
				cashx:Destroy()
			end
		end
	end, { players })

	useEffect(function()
		if not CashIntances then
			return
		end
		for i, cashInstance: IntValue in CashIntances do
			cashInstance.Value = PDDummy.Cash
		end
	end, { cash })

	local function BuyButton(ItemId: string): boolean
		local success = false
		local total = PDDummy.Cash - ICDummies[ItemId].Price
		if total >= 0 then
			PDDummy.Cash = total
			setCash(PDDummy.Cash)
			PDDummy.OwnedItems[ItemId] = true
			for i, unlockedItemId in ICDummies[ItemId].Unlocks or {} do
				PDDummy.UnlockedItems[unlockedItemId] = true
			end
			PDDummy.Rate += 5
			setPlayerData(function(prev)
				return table.clone(PDDummy)
			end)

			success = true
		else
			warn("Not enough")
		end
		warn(success)
		return success
	end

	local unowned
	local ownedcount = 0
	for i, itemConfig in ipairs(ICDummies) do
		if unowned then
			unowned += 1
		end
		local unlocked = PlayerData.UnlockedItems[itemConfig.ItemId]
		if not unlocked then
			continue
		end

		local owned = PlayerData.OwnedItems[itemConfig.ItemId]
		if not owned and not unowned then
			unowned = 1
		end
		if (unowned and unowned > 5) and not owned then
			break
		end
		children[itemConfig.ItemId] = e(Item, {
			key = itemConfig.ItemId,
			Owned = owned,
			ItemId = itemConfig.ItemId,
			DisplayName = itemConfig.DisplayName,
			Price = itemConfig.Price,
			RootArea = workspace.EmptyBase.RootArea,
			BuyButton = BuyButton,
		})
	end
	return e("Folder", {
		Name = "ItemRenderer",
	}, children)
end

return ItemRenderer
