local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type Item = sharedtypes.Item

local itemConfigs = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local variationConfigs = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
local tierConfigs = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)

function FormatItemLabelText(item: Item): string
	local cfg = itemConfigs[item.ItemId]
	local varcfg = variationConfigs[item.VariationId] or variationConfigs[((item.VariationId or "") :: string):lower()]
	local tier = tierConfigs[item.TierId] or tierConfigs[((item.TierId or "") :: string):lower()]

	-- Name, VariationId, Tier, and Rate Display
	local name = cfg and cfg.DisplayName or "Error"
	local varColor = varcfg and varcfg.ColorPrimary and varcfg.ColorPrimary:ToHex() or "000000"
	local varName = --
		varcfg --
			and varcfg.VariationId == "none"
			and "" --[[If none]]
		or varcfg and varcfg.DisplayName
		or "Error"
	local tierColor = tier and tier.ColorPrimary:ToHex() or "000000"
	local tierName = tier and tier.DisplayName or "Error"
	local rate = Alyanum.new(item.Rate):toString()

	local text
	if varcfg and varcfg.VariationId ~= "none" then
		text = --
			([[<font size="18">%s</font>
<font color="#%s">%s</font> | <font color="#%s">%s</font>
<font>%s/s</font>]]):format(name, varColor, varName, tierColor, tierName, rate)
	else
		text = --
			([[<font>%s</font>
<font color="#%s">%s</font>
<font>%s/s</font>]]):format(name, tierColor, tierName, rate)
	end
	return text
end

return { FormatItemLabelText = FormatItemLabelText }
