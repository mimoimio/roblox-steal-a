-- --
-- -- TreeSpawnService
-- -- Spawns static tree models at grid positions once on server start.
-- --
-- -- CONFIGURATION:
-- --   TREE_MODEL_FOLDER: Folder containing tree models (Model instances)
-- --   TREE_COUNT: Number of trees to spawn
-- --   GridService: Used for grid-based placement
-- --   TreesFolder: All spawned trees parented here in workspace
-- --
-- local TREE_MODEL_FOLDER = game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Models"):WaitForChild("Trees")
-- local TREE_COUNT = 100

-- local TreeSpawnService = {}
-- TreeSpawnService.__index = TreeSpawnService

-- local GridService = require(script.Parent.GridService)
-- local rng = Random.new()

-- function TreeSpawnService.initialize()
-- 	local treesFolder = workspace:FindFirstChild("TreesFolder") or Instance.new("Folder", workspace)
-- 	treesFolder.Name = "TreesFolder"

-- 	task.spawn(function()
-- 		while not GridService.isInitialized do
-- 			task.wait(0.1)
-- 			if #GridService.Positions > 0 then
-- 				break
-- 			end
-- 		end

-- 		local treeModels = {}
-- 		for _, m in ipairs(TREE_MODEL_FOLDER:GetChildren()) do
-- 			if m:IsA("Model") then
-- 				table.insert(treeModels, m)
-- 			end
-- 		end
-- 		if #treeModels == 0 then
-- 			warn("No tree models found in", TREE_MODEL_FOLDER:GetFullName())
-- 			return
-- 		end

-- 		for i = 1, TREE_COUNT do
-- 			local template = treeModels[rng:NextInteger(1, #treeModels)]
-- 			local pos = GridService.RemoveRandom()
-- 				or Vector3.new(rng:NextNumber(-500, 500), 0, rng:NextNumber(-500, 500))
-- 			local tree = template:Clone()
-- 			tree.Name = "Tree_" .. i
-- 			tree.Parent = treesFolder
-- 			if tree.PrimaryPart then
-- 				tree.PrimaryPart.Anchored = true
-- 				tree:PivotTo(
-- 					CFrame.new(pos)
-- 						* CFrame.Angles(
-- 							(math.random() - 0.5) * math.pi * 15 / 180,
-- 							math.pi * 2,
-- 							(math.random() - 0.5) * math.pi * 15 / 180
-- 						)
-- 				)
-- 			else
-- 				for _, d in ipairs(tree:GetDescendants()) do
-- 					if d:IsA("BasePart") then
-- 						d.Anchored = true
-- 						tree:PivotTo(CFrame.new(pos))
-- 						break
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end)
-- end

-- return TreeSpawnService
return { initialize = function() end }
