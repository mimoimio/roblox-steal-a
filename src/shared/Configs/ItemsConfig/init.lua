type ItemConfig = {
	ItemId: string,
	DisplayName: string,
	Rate: number,
	Tier: string,
	Price: number,
	ItemTip: string,
	FlashEffect: string,
	Entry: (() -> nil)?,
	Growth: (() -> nil)?,
	Removed: (() -> nil)?,
}

local isserver = game:GetService("RunService"):IsServer()
local ItemsConfig = require(script.RawConfigs)

function getFuncString(string: string)
	return [[local EffectHelpers = require(game.ServerScriptService.Server.Utils.EffectHelpers)
return ]] .. string:match("%s*function.*end"):gsub("\t", "")
end
-- iterate each to process special effects only on server
for i, config: ItemConfig in ipairs(ItemsConfig) do
	ItemsConfig[config.ItemId] = config
	if not isserver then
		config.Entry = nil
		config.Growth = nil
		config.Removed = nil
		continue
	end

	local success, EntryFunction = xpcall(function()
		if not config.Entry then
			return
		end
		local funcstring = getFuncString(config.Entry)
		if not funcstring then
			warn("NO FUNCSTRING")
		else
			-- warn("\nfuncstring\n\n", funcstring)
		end

		local func = loadstring(funcstring)()
		return func
	end, function(...) end)
	config.Entry = success and EntryFunction or nil

	local success, GrowthFunction = xpcall(function()
		if not config.Growth then
			return
		end
		local funcstring = getFuncString(config.Growth)
		if not funcstring then
			warn("NO FUNCSTRING")
		else
			-- warn("\nfuncstring\n\n", funcstring)
		end

		local func = loadstring(funcstring)()
		return func
	end, function(...) end)
	config.Growth = success and GrowthFunction or nil

	local success, RemovedFunction = xpcall(function()
		if not config.Removed then
			return
		end
		local funcstring = getFuncString(config.Removed)
		if not funcstring then
			warn("NO FUNCSTRING")
		else
			-- warn("\nfuncstring\n\n", funcstring)
		end

		local func = loadstring(funcstring)()
		return func
	end, function(...) end)
	config.Removed = success and RemovedFunction or nil
end

return ItemsConfig
