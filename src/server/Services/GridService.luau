local self: { isInitialized: boolean?, Initialized: RBXScriptSignal } = {}

self.Positions = {}

self.Random = Random.new(1)
local perlinRandomX, perlinRandomZ = self.Random:NextNumber(), self.Random:NextNumber()
self.width = 100
self.gridSize = 10
local zoom = 100
local frequency = 0.9
local amplitude = 10

function self.initialize()
	local InitializedEvent = Instance.new("BindableEvent")
	self.Initialized = InitializedEvent.Event
	task.spawn(function()
		--print("Started")
		local param = RaycastParams.new()
		param.FilterDescendantsInstances = {
			-- workspace.Decors,
			-- workspace:WaitForChild("ItemsFolder"),
			workspace.TreeTerrains,
			-- workspace.Utilities,
		}

		workspace.Baseplate.Transparency = 1
		workspace.Baseplate.Texture.Transparency = 1

		param.FilterType = Enum.RaycastFilterType.Exclude

		for i = 1, self.width do
			task.spawn(function()
				for j = 1, self.width do
					local i = i
					local gridVector = Vector3.new(i - self.width / 2, 1, j - self.width / 2) * self.gridSize

					if i == 1 or j == 1 or i == self.width or j == self.width then
						local terrainCFrame = CFrame.new(gridVector)
						local terrainSize = Vector3.one * self.gridSize + Vector3.new(0, 100, 0)
						workspace.Terrain:FillBlock(terrainCFrame, terrainSize, Enum.Material.Grass)
						continue
					end

					local noise = math.noise(
						gridVector.X / zoom * frequency + 0.1 * perlinRandomX,
						nil,
						gridVector.Z / zoom * frequency + 0.1 * perlinRandomZ
					)

					local clrNoise = math.clamp(0.5 + noise, 0, 1)

					-- Comment out part generation - using workspace.Terrain instead
					--[[
                    local part = Instance.new("Part", workspace.TreeTerrains)
                    part.Anchored = true
                    part.Size = Vector3.one * self.gridSize + Vector3.new(0, amplitude, 0)
                    part.Color = Color3.new(clrNoise, 0.4 + 0.5 * clrNoise, 0.2 + 0.2 * clrNoise)
                    part.Material = "Grass"
                    ]]

					local result = workspace:Blockcast(
						CFrame.new(gridVector),
						Vector3.new(1, 1 / self.gridSize, 1) * self.gridSize,
						Vector3.new(0, -amplitude * self.gridSize, 0),
						param
					)

					if not result then
						print("No result")
					elseif
						result.Instance:IsDescendantOf(workspace.Plots)
						or result.Instance:IsDescendantOf(workspace.Paths)
						or result.Instance:IsDescendantOf(workspace.Shops)
					then
						-- Comment out part positioning - using workspace.Terrain instead
						-- part:PivotTo(
						-- 	CFrame.new(
						-- 		Vector3.new(gridVector.X, result.Position.Y, gridVector.Z)
						-- 			- Vector3.new(0, part.Size.Y / 2 + 0.5, 0)
						-- 	)
						-- )
						local terrainSize = Vector3.new(self.gridSize, self.gridSize + amplitude, self.gridSize)
						local terrainCFrame = CFrame.new(
							Vector3.new(gridVector.X, result.Position.Y, gridVector.Z)
								- Vector3.new(0, self.gridSize + amplitude / 2, 0)
						)
						workspace.Terrain:FillBlock(terrainCFrame, terrainSize, Enum.Material.Mud)
						continue
					end

					local noisedPosition = gridVector + Vector3.new(0, amplitude * noise, 0) - Vector3.new(0, 10, 0)

					table.insert(self.Positions, noisedPosition)

					-- Generate terrain using FillBlock
					local terrainCFrame = CFrame.new(noisedPosition - Vector3.new(0, self.gridSize + 4, 0))
					local terrainSize = Vector3.new(self.gridSize, self.gridSize + amplitude, self.gridSize)
					workspace.Terrain:FillBlock(terrainCFrame, terrainSize, Enum.Material.Grass)

					-- Comment out part positioning - using workspace.Terrain instead
					--[[
                    part:PivotTo(CFrame.new(noisedPosition - Vector3.new(0, part.Size.Y / 2, 0)))
                    ]]
				end
			end)
		end
		repeat
			local prev = #self.Positions
			task.wait()
		until #self.Positions <= prev
		workspace.Baseplate.CanCollide = false
		self.isInitialized = true
		InitializedEvent:Fire()
	end)
end

function self.Remove(index)
	if self.Positions[index] then
		if index == #self.Positions then
			return table.remove(self.Positions, #self.Positions)
		else
			local value = self.Positions[index]
			self.Positions[index] = table.remove(self.Positions, #self.Positions)
			return value
		end
	else
		return false
	end
end

function self.RemoveRandom()
	-- local r = self.Random:NextInteger(1, #self.Positions)
	local r = Random.new():NextInteger(1, #self.Positions)
	return self.Remove(r)
end

function self.InsertPosition(Position)
	table.insert(self.Positions, Position)
	return true
end

return self
