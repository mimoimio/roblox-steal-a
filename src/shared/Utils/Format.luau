local sharedtypes = require(game.ReplicatedStorage.Shared.types)
type Item = sharedtypes.Item

local itemConfigs = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)
local variationConfigs = require(game.ReplicatedStorage.Shared.Configs.VariationsConfig)
local tierConfigs = require(game.ReplicatedStorage.Shared.Configs.TiersConfig)
local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)

local EvalColorSequence = require(script.Parent.EvalColorSequence)
-- local bigNumColors = {
-- 	Color3.new(1, 1, 1),
-- 	Color3.new(1, 0.5, 0.6),
-- 	Color3.new(0.8, 0.7, 0.2),
-- 	Color3.new(0.2, 0.3, 1),
-- }

local bigNumColors = {
	Color3.new(1, 1, 1),
	Color3.new(0.5, 0.5, 1),
	Color3.new(0.5, 1, 0.5),
	Color3.new(1, 0.5, 0.5),
	Color3.new(1, 1, 0),
	Color3.new(0, 1, 1),
	Color3.new(1, 0, 1),
	Color3.new(0.5, 0.5, 0.5),
	Color3.new(1, 0, 0),
	Color3.new(0, 1, 0),
	Color3.new(0, 0, 1),
	Color3.new(1, 1, 0.5),
	Color3.new(0.5, 1, 1),
	Color3.new(1, 0.5, 1),
}
local sequences: { ColorSequenceKeypoint } = {}
for i, color in bigNumColors do
	-- warn((i - 1) / (#bigNumColors - 1), color)
	table.insert(sequences, ColorSequenceKeypoint.new((i - 1) / (#bigNumColors - 1), color))
end
local bignumColorSequence = ColorSequence.new(sequences)

function FormatItemLabelText(item: Item, isMultiplied: boolean?): string
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

	local rateText = string.format('<font color="#%s">%s/s</font>', rateColor(item.Rate):ToHex(), rate)
	if isMultiplied then
		rateText = string.format('<font color="#FFD700">×</font> %s', rateText)
	end

	local text
	if varcfg and varcfg.VariationId ~= "none" then
		text = ([[<font size="18">%s</font>
<font color="#%s">%s</font> | <font color="#%s">%s</font>
%s]]):format(name, varColor, varName, tierColor, tierName, rateText)
	else
		text = ([[<font>%s</font>
<font color="#%s">%s</font>
%s]]):format(name, tierColor, tierName, rateText)
	end
	return text
end

function rateColor(rate: number): Color3
	local spectrum = math.clamp(math.log10(rate) / math.log10(9e9), 0, 1)
	return EvalColorSequence(bignumColorSequence, spectrum)
end
-- local Alyanum = require(game.ReplicatedStorage.Packages.Alyanum)
-- local rateColor = require(game.ReplicatedStorage.Shared.Utils.Format).rateColor
-- local s = ""
-- for i = 0, 400, 3 do
-- 	local n = 10 ^ i
-- 	s ..= ([[<font color="#%s">%s</font>]]):format(rateColor(n):ToHex(), "10^" .. i .. " = ")
-- 	s ..= ([[<font color="#%s">%s/</font>]]):format(rateColor(n):ToHex(), Alyanum.new(n):toString()) .. "\n"
-- end
-- warn(s)

return {
	FormatItemLabelText = FormatItemLabelText,
	rateColor = rateColor,
}
