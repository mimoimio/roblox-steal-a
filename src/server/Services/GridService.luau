local self: { isInitialized: boolean?, Initialized: RBXScriptSignal } = {}

self.Positions = {}

self.Random = Random.new(1)
self.width = 200
self.gridSize = 4

function self.initialize()
	local InitializedEvent = Instance.new("BindableEvent")
	self.Initialized = InitializedEvent.Event
	task.spawn(function()
		--print("Started")
		local param = RaycastParams.new()
		param.FilterDescendantsInstances = {
			workspace.TreeTerrains,
		}

		param.FilterType = Enum.RaycastFilterType.Exclude

		for i = 1, self.width do
			task.spawn(function()
				for j = 1, self.width do
					local i = i
					local gridVector = Vector3.new(i - self.width / 2, 20, j - self.width / 2) * self.gridSize

					local result: RaycastResult = workspace:Raycast(gridVector, Vector3.new(0, -400, 0), param)

					if
						not result
						or result.Instance:IsDescendantOf(workspace.Plots)
						or result.Instance:IsDescendantOf(workspace.Paths)
						or result.Instance:IsDescendantOf(workspace.Shops)
					then
						continue
					end
					table.insert(self.Positions, result.Position)
				end
			end)
		end
		repeat
			local prev = #self.Positions
			task.wait()
		until #self.Positions <= prev
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
	local r = Random.new():NextInteger(1, #self.Positions)
	return self.Remove(r)
end

function self.InsertPosition(Position)
	table.insert(self.Positions, Position)
	return true
end

--[[



]]

return self
