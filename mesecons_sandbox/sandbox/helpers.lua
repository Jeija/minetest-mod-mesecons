--------------------------------------------------------------------------------
-- Localize functions to avoid table lookups (better performance).
local string_sub, string_find = string.sub, string.find

--------------------------------------------------------------------------------
local function basic_dump(o)
	local tp = type(o)
	if tp == "number" then
		return tostring(o)
	elseif tp == "string" then
		return string.format("%q", o)
	elseif tp == "boolean" then
		return tostring(o)
	elseif tp == "nil" then
		return "nil"
	-- Uncomment for full function dumping support.
	-- Not currently enabled because bytecode isn't very human-readable and
	-- dump's output is intended for humans.
	--elseif tp == "function" then
	--	return string.format("loadstring(%q)", string.dump(o))
	else
		return string.format("<%s>", tp)
	end
end

local keywords = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["goto"] = true,  -- Lua 5.2
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["until"] = true,
	["while"] = true,
}
local function is_valid_identifier(str)
	if not string_find("^[a-zA-Z_][a-zA-Z0-9_]*$") or keywords[str] then
		return false
	end
	return true
end

--------------------------------------------------------------------------------
-- Dumps values in a line-per-value format.
-- For example, {test = {"Testing..."}} becomes:
--   _["test"] = {}
--   _["test"][1] = "Testing..."
-- This handles tables as keys and circular references properly.
-- It also handles multiple references well, writing the table only once.
-- The dumped argument is internal-only.

local function dump2(o, name, dumped)
	name = name or "_"
	-- "dumped" is used to keep track of serialized tables to handle
	-- multiple references and circular tables properly.
	-- It only contains tables as keys.  The value is the name that
	-- the table has in the dump, eg:
	-- {x = {"y"}} -> dumped[{"y"}] = '_["x"]'
	dumped = dumped or {}
	if type(o) ~= "table" then
		return string.format("%s = %s\n", name, basic_dump(o))
	end
	if dumped[o] then
		return string.format("%s = %s\n", name, dumped[o])
	end
	dumped[o] = name
	-- This contains a list of strings to be concatenated later (because
	-- Lua is slow at individual concatenation).
	local t = {}
	for k, v in pairs(o) do
		local keyStr
		if type(k) == "table" then
			if dumped[k] then
				keyStr = dumped[k]
			else
				-- Key tables don't have a name, so use one of
				-- the form _G["table: 0xFFFFFFF"]
				keyStr = string.format("_G[%q]", tostring(k))
				-- Dump key table
				t[#t + 1] = dump2(k, keyStr, dumped)
			end
		else
			keyStr = basic_dump(k)
		end
		local vname = string.format("%s[%s]", name, keyStr)
		t[#t + 1] = dump2(v, vname, dumped)
	end
	return string.format("%s = {}\n%s", name, table.concat(t))
end

--------------------------------------------------------------------------------
-- This dumps values in a one-statement format.
-- For example, {test = {"Testing..."}} becomes:
-- [[{
-- 	test = {
-- 		"Testing..."
-- 	}
-- }]]
-- This supports tables as keys, but not circular references.
-- It performs poorly with multiple references as it writes out the full
-- table each time.
-- The indent field specifies a indentation string, it defaults to a tab.
-- Use the empty string to disable indentation.
-- The dumped and level arguments are internal-only.

function dump(o, indent, nested, level)
	local t = type(o)
	if not level and t == "userdata" then
		-- when userdata (e.g. player) is passed directly, print its metatable:
		return "userdata metatable: " .. dump(getmetatable(o))
	end
	if t ~= "table" then
		return basic_dump(o)
	end
	-- Contains table -> true/nil of currently nested tables
	nested = nested or {}
	if nested[o] then
		return "<circular reference>"
	end
	nested[o] = true
	indent = indent or "\t"
	level = level or 1
	local t = {}
	local dumped_indexes = {}
	for i, v in ipairs(o) do
		t[#t + 1] = dump(v, indent, nested, level + 1)
		dumped_indexes[i] = true
	end
	for k, v in pairs(o) do
		if not dumped_indexes[k] then
			if type(k) ~= "string" or not is_valid_identifier(k) then
				k = "["..dump(k, indent, nested, level + 1).."]"
			end
			v = dump(v, indent, nested, level + 1)
			t[#t + 1] = k.." = "..v
		end
	end
	nested[o] = nil
	if indent ~= "" then
		local indent_str = "\n"..string.rep(indent, level)
		local end_indent_str = "\n"..string.rep(indent, level - 1)
		return string.format("{%s%s%s}",
				indent_str,
				table.concat(t, ","..indent_str),
				end_indent_str)
	end
	return "{"..table.concat(t, ", ").."}"
end

--------------------------------------------------------------------------------
function string.split(str, delim, include_empty, max_splits, sep_is_pattern)
	delim = delim or ","
	max_splits = max_splits or -2
	local items = {}
	local pos, len = 1, #str
	local plain = not sep_is_pattern
	max_splits = max_splits + 1
	repeat
		local np, npe = string_find(str, delim, pos, plain)
		np, npe = (np or (len+1)), (npe or (len+1))
		if (not np) or (max_splits == 1) then
			np = len + 1
			npe = np
		end
		local s = string_sub(str, pos, np - 1)
		if include_empty or (s ~= "") then
			max_splits = max_splits - 1
			items[#items + 1] = s
		end
		pos = npe + 1
	until (max_splits == 0) or (pos > (len + 1))
	return items
end
