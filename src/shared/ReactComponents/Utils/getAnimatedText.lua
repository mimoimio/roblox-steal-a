local length = 90
local function getAnimatedText(text, currentWave)
	local parts = {}
	local index = 0
	local inTag = false
	local currentTag = ""

	for first, last in utf8.graphemes(text) do
		local char = text:sub(first, last)

		if char == "<" then
			inTag = true
			currentTag = char
		elseif inTag then
			currentTag = currentTag .. char
			if char == ">" then
				table.insert(parts, currentTag)
				inTag = false
				currentTag = ""
			end
		else
			local escapedChar = char
			if char == "<" then
				escapedChar = "&lt;"
			elseif char == ">" then
				escapedChar = "&gt;"
			elseif char == "&" then
				escapedChar = "&amp;"
			end

			-- local size = 18 + ((index + currentWave) % length)
			local t = ((index + currentWave) % length) / length / 4 + 0.75
			table.insert(parts, string.format('<mark color="#ffffff" transparency="%.2f">%s</mark>', t, escapedChar))
			index += 1
		end
	end

	return table.concat(parts)
end

return getAnimatedText
