local React = require(game.ReplicatedStorage.Packages.React)
local e = React.createElement
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)

local rootfolder = Instance.new("Folder", workspace)
rootfolder.Name = "rootfolder"
local root = ReactRoblox.createRoot(rootfolder)
root:render(e("Folder", {}, e(require(script.ItemRenderer))))
