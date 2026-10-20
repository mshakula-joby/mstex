-- common-code.lua
--
-- Glyph side bearings for \code (common.sty): the blank space between a glyph's advance box and its ink.
-- commoncode.bearing(<box>, "l") prints, in sp, the space left of the ink of the first glyph in box register
-- <box>, and commoncode.bearing(<box>, "r") the space right of the ink of the last one. It is 0 when there is no
-- glyph or the font does not say (fonts loaded by luaotfload keep the outlines' bounding boxes).

commoncode = commoncode or {}

local glyph_id = node.id("glyph")
local identifiers = fonts and fonts.hashes and fonts.hashes.identifiers

local function bearings(g)
	local f = identifiers and identifiers[g.font]
	local ch = f and f.characters and f.characters[g.char]
	local raw = f and f.shared and f.shared.rawdata
	local d = raw and raw.descriptions and raw.descriptions[g.char]
	if not (ch and d and d.boundingbox and d.width and d.width > 0) then
		return 0, 0
	end
	local scale = ch.width / d.width
	local bb = d.boundingbox
	return math.max(0, bb[1] * scale), math.max(0, (d.width - bb[3]) * scale)
end

function commoncode.bearing(box, side)
	local b = tex.getbox(box)
	local first, last
	for g in node.traverse_id(glyph_id, b and b.list) do
		first = first or g
		last = g
	end
	local value = 0
	if first then
		if side == "l" then
			value = select(1, bearings(first))
		else
			value = select(2, bearings(last))
		end
	end
	tex.sprint(string.format("%dsp", math.floor(value)))
end
