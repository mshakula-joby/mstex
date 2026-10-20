-- common-code.lua
--
-- The pills of \code (common.sty), drawn by LuaTeX.
--
-- \code typesets its text with the attribute common@codeattr set to a number of its own, which keys the style
-- registered by commoncode.style(<number>, <ht>, <dp>, <radius>, "<r g b>") (dimensions in sp, color in 0..1).
-- Between the chunks of the code there are discretionaries: empty ones where the line may break inside a word,
-- and at spaces one whose no-break text is the space.
--
-- Before the line breaking (pre_linebreak_filter), and in boxes (hpack_filter), each run of code gets its
-- padding: a kern at its start and at its end, and the same kerns as the pre-break and post-break text of each
-- discretionary, so that a line ends and starts with the padding. The padding is the radius less the side
-- bearing of the glyph next to it (the blank space between its advance box and its ink), so the pill hugs the
-- ink.
-- After the line breaking (post_linebreak_filter), and in boxes, each run of code in a line gets one rounded
-- rectangle behind it, a PDF literal: one shape per line, with no seams.

commoncode = commoncode or {}

local attr = luatexbase.registernumber("common@codeattr")
local padattr = luatexbase.registernumber("common@codepadattr") -- set on the runs that have their padding
local styles = {}

local GLYPH = node.id("glyph")
local DISC = node.id("disc")
local HLIST = node.id("hlist")
local identifiers = fonts and fonts.hashes and fonts.hashes.identifiers

function commoncode.style(id, ht, dp, r, rgb)
	styles[id] = { ht = ht, dp = dp, r = r, rgb = rgb }
end

-- The side bearings of glyph g, in sp (0 when the font does not say).
local function bearings(g)
	if not g then
		return 0, 0
	end
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

local function kern(width, id)
	local k = node.new("kern")
	k.kern = width
	node.set_attribute(k, attr, id)
	node.set_attribute(k, padattr, 1)
	return k
end

-- The last node of the run of code id that starts at n.
local function run_end(n, id)
	while n.next and node.has_attribute(n.next, attr) == id do
		n = n.next
	end
	return n
end

-- The first glyph from n on (forward) or back (backward), within the run first..last.
local function next_glyph(n, last)
	while n do
		if n.id == GLYPH then
			return n
		end
		if n == last then
			return nil
		end
		n = n.next
	end
end
local function prev_glyph(n, first)
	while n do
		if n.id == GLYPH then
			return n
		end
		if n == first then
			return nil
		end
		n = n.prev
	end
end

-- The padding of the runs of code in the list head, once for each run.
local function pad(head)
	local n = head
	while n do
		local id = node.has_attribute(n, attr)
		local s = id and styles[id]
		if s and not node.has_attribute(n, padattr) then
			local first, last = n, run_end(n, id)
			local m = first
			while true do
				node.set_attribute(m, padattr, 1)
				if m.id == DISC then
					local _, rsb = bearings(prev_glyph(m.prev, first))
					local lsb = bearings(next_glyph(m.next, last))
					m.pre = kern(s.r - rsb, id)
					m.post = kern(s.r - lsb, id)
				end
				if m == last then
					break
				end
				m = m.next
			end
			local lsb = bearings(next_glyph(first, last))
			local _, rsb = bearings(prev_glyph(last, first))
			local k1, k2 = kern(s.r - lsb, id), kern(s.r - rsb, id)
			head = node.insert_before(head, first, k1)
			node.insert_after(head, last, k2)
			n = k2.next
		else
			n = n.next
		end
	end
	return head
end

-- A rounded rectangle from the current point, w wide, from dp below the baseline to ht above, radius r (sp).
local BP = 65781.76
local function pill(w, s)
	local x0, x1 = 0, w / BP
	local y0, y1 = -s.dp / BP, s.ht / BP
	local r = math.min(s.r / BP, (x1 - x0) / 2, (y1 - y0) / 2)
	local k = 0.5523 * r
	local f = function(v) return string.format("%.3f", v) end
	local p = {
		"q", s.rgb, "rg",
		f(x0 + r), f(y0), "m",
		f(x1 - r), f(y0), "l",
		f(x1 - r + k), f(y0), f(x1), f(y0 + r - k), f(x1), f(y0 + r), "c",
		f(x1), f(y1 - r), "l",
		f(x1), f(y1 - r + k), f(x1 - r + k), f(y1), f(x1 - r), f(y1), "c",
		f(x0 + r), f(y1), "l",
		f(x0 + r - k), f(y1), f(x0), f(y1 - r + k), f(x0), f(y1 - r), "c",
		f(x0), f(y0 + r), "l",
		f(x0), f(y0 + r - k), f(x0 + r - k), f(y0), f(x0 + r), f(y0), "c",
		"f", "Q",
	}
	local lit = node.new("whatsit", "pdf_literal")
	lit.mode = 0 -- relative to the current point
	lit.data = table.concat(p, " ")
	return lit
end

-- One pill behind each run of code in the horizontal list head, whose glue is set by box (or natural without).
local function draw(head, box)
	local n = head
	while n do
		local id = node.has_attribute(n, attr)
		local s = id and styles[id]
		if s then
			local first, last = n, run_end(n, id)
			local w
			if box then
				w = node.dimensions(box.glue_set, box.glue_sign, box.glue_order, first, last.next)
			else
				w = node.dimensions(first, last.next)
			end
			head = node.insert_before(head, first, pill(w, s))
			-- Drawn: the run is no longer code, so that it is not drawn again.
			local m = first
			while true do
				node.unset_attribute(m, attr)
				if m == last then
					break
				end
				m = m.next
			end
			n = last.next
		else
			n = n.next
		end
	end
	return head
end

luatexbase.add_to_callback("pre_linebreak_filter", function(head)
	return pad(head)
end, "common.code.pad")

luatexbase.add_to_callback("post_linebreak_filter", function(head)
	for line in node.traverse_id(HLIST, head) do
		line.list = draw(line.list, line)
	end
	return head
end, "common.code.draw")

luatexbase.add_to_callback("hpack_filter", function(head)
	return draw(pad(head))
end, "common.code.box")
