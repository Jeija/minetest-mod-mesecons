local S = minetest.get_translator("mesecons_microcontroller")
local F = minetest.formspec_escape

local EEPROM_SIZE = 255

local microc_rules = {}
local yc = {}

for a = 0, 1 do
for b = 0, 1 do
for c = 0, 1 do
for d = 0, 1 do
local nodename = "mesecons_microcontroller:microcontroller"..tostring(d)..tostring(c)..tostring(b)..tostring(a)
local top = "jeija_microcontroller_top.png"
if tostring(a) == "1" then
	top = top.."^jeija_microcontroller_LED_A.png"
end
if tostring(b) == "1" then
	top = top.."^jeija_microcontroller_LED_B.png"
end
if tostring(c) == "1" then
	top = top.."^jeija_microcontroller_LED_C.png"
end
if tostring(d) == "1" then
	top = top.."^jeija_microcontroller_LED_D.png"
end
local groups
if tostring(d)..tostring(c)..tostring(b)..tostring(a) ~= "0000" then
	groups = {dig_immediate=2, not_in_creative_inventory=1, mesecon = 3, overheat = 1}
else
	groups = {dig_immediate=2, mesecon = 3, overheat = 1}
end
local rules={}
if (a == 1) then table.insert(rules, {x = -1, y = 0, z =  0}) end
if (b == 1) then table.insert(rules, {x =  0, y = 0, z =  1}) end
if (c == 1) then table.insert(rules, {x =  1, y = 0, z =  0}) end
if (d == 1) then table.insert(rules, {x =  0, y = 0, z = -1}) end

local input_rules={}
if (a == 0) then table.insert(input_rules, {x = -1, y = 0, z =  0, name = "A"}) end
if (b == 0) then table.insert(input_rules, {x =  0, y = 0, z =  1, name = "B"}) end
if (c == 0) then table.insert(input_rules, {x =  1, y = 0, z =  0, name = "C"}) end
if (d == 0) then table.insert(input_rules, {x =  0, y = 0, z = -1, name = "D"}) end
microc_rules[nodename] = rules

local mesecons = {effector =
{
	rules = input_rules,
	action_change = function (pos, node, rulename, newstate)
		yc.update_real_portstates(pos, node, rulename, newstate)
		yc.update(pos)
	end
}}
if nodename ~= "mesecons_microcontroller:microcontroller0000" then
	mesecons.receptor = {
		state = mesecon.state.on,
		rules = rules
	}
end

minetest.register_node(nodename, {
	description = S("Microcontroller"),
	drawtype = "nodebox",
	tiles = {
		top,
		"jeija_microcontroller_bottom.png",
		"jeija_microcontroller_sides.png",
		"jeija_microcontroller_sides.png",
		"jeija_microcontroller_sides.png",
		"jeija_microcontroller_sides.png"
		},

	sunlight_propagates = true,
	paramtype = "light",
	is_ground_content = false,
	walkable = true,
	groups = groups,
	drop = "mesecons_microcontroller:microcontroller0000 1",
	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, -8/16, 8/16, -5/16, 8/16 },
	},
	node_box = {
		type = "fixed",
		fixed = {
			{ -8/16, -8/16, -8/16, 8/16, -7/16, 8/16 }, -- bottom slab
			{ -5/16, -7/16, -5/16, 5/16, -6/16, 5/16 }, -- circuit board
			{ -3/16, -6/16, -3/16, 3/16, -5/16, 3/16 }, -- IC
		}
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("code", "")
		meta:set_string("formspec", "size[9,2.5]"..
			"field[0.256,-0.2;9,2;code;"..F(S("Code:"))..";]"..
			"button[0  ,0.2;1.5,3;band;"..F(S("AND")).."]"..
			"button[1.5,0.2;1.5,3;bxor;"..F(S("XOR")).."]"..
			"button[3  ,0.2;1.5,3;bnot;"..F(S("NOT")).."]"..
			"button[4.5,0.2;1.5,3;bnand;"..F(S("NAND")).."]"..
			"button[6  ,0.2;1.5,3;btflop;"..F(S("T-Flop")).."]"..
			"button[7.5,0.2;1.5,3;brsflop;"..F(S("RS-Flop")).."]"..
			"button_exit[3.5,1;2,3;program;"..F(S("Program")).."]")
		meta:set_string("infotext", S("Unprogrammed Microcontroller"))
		local r = ""
		for i=1, EEPROM_SIZE+1 do r=r.."0" end --Generate a string with EEPROM_SIZE*"0"
		meta:set_string("eeprom", r)
	end,
	on_receive_fields = function(pos, formanme, fields, sender)
		local player_name = sender:get_player_name()
		if minetest.is_protected(pos, player_name) and
				not minetest.check_player_privs(player_name, {protection_bypass=true}) then
			minetest.record_protection_violation(pos, player_name)
			return
		end
		local meta = minetest.get_meta(pos)
		if fields.band then
			fields.code = "sbi(C, A&B) :A and B are inputs, C is output"
		elseif fields.bxor then
			fields.code = "sbi(C, A~B) :A and B are inputs, C is output"
		elseif fields.bnot then
			fields.code = "sbi(B, !A) :A is input, B is output"
		elseif fields.bnand then
			fields.code = "sbi(C, !A|!B) :A and B are inputs, C is output"
		elseif fields.btflop then
			fields.code = "if(A)sbi(1,1);if(!A&#1)sbi(B,!B)sbi(1,0); if(C)off(B,1); :A is input, B is output (Q), C is reset, toggles with falling edge"
		elseif fields.brsflop then
			fields.code = "if(A)on(C);if(B)off(C); :A is S (Set), B is R (Reset), C is output (R dominates)"
		end
		if fields.code == nil then return end

		meta:set_string("code", fields.code)
		meta:set_string("formspec", "size[9,2.5]"..
		"field[0.256,-0.2;9,2;code;"..F(S("Code:"))..";"..minetest.formspec_escape(fields.code).."]"..
		"button[0  ,0.2;1.5,3;band;"..F(S("AND")).."]"..
		"button[1.5,0.2;1.5,3;bxor;"..F(S("XOR")).."]"..
		"button[3  ,0.2;1.5,3;bnot;"..F(S("NOT")).."]"..
		"button[4.5,0.2;1.5,3;bnand;"..F(S("NAND")).."]"..
		"button[6  ,0.2;1.5,3;btflop;"..F(S("T-Flop")).."]"..
		"button[7.5,0.2;1.5,3;brsflop;"..F(S("RS-Flop")).."]"..
		"button_exit[3.5,1;2,3;program;"..F(S("Program")).."]")
		meta:set_string("infotext", S("Programmed Microcontroller"))
		yc.reset (pos)
		yc.update(pos)
	end,
	sounds = default.node_sound_stone_defaults(),
	mesecons = mesecons,
	after_dig_node = function (pos, node)
		rules = microc_rules[node.name]
		mesecon.receptor_off(pos, rules)
	end,
	on_blast = mesecon.on_blastnode,
})
end
end
end
end

if minetest.get_modpath("mesecons_luacontroller") then
	minetest.register_craft({
		type = "shapeless",
		output = "mesecons_microcontroller:microcontroller0000",
		recipe = {"mesecons_luacontroller:luacontroller0000"},
	})
	minetest.register_craft({
		type = "shapeless",
		output = "mesecons_luacontroller:luacontroller0000",
		recipe = {"mesecons_microcontroller:microcontroller0000"},
	})
else
	minetest.register_craft({
		output = 'craft "mesecons_microcontroller:microcontroller0000" 2',
		recipe = {
			{'mesecons_materials:silicon', 'mesecons_materials:silicon', 'group:mesecon_conductor_craftable'},
			{'mesecons_materials:silicon', 'mesecons_materials:silicon', 'group:mesecon_conductor_craftable'},
			{'group:mesecon_conductor_craftable', 'group:mesecon_conductor_craftable', ''},
		}
	})
end

yc.reset = function(pos)
	yc.action(pos, {a=false, b=false, c=false, d=false})
	local meta = minetest.get_meta(pos)
	meta:set_int("afterid", 0)
	local r = ""
	for i=1, EEPROM_SIZE+1 do r=r.."0" end --Generate a string with EEPROM_SIZE*"0"
	meta:set_string("eeprom", r)
end

yc.update = function(pos)
	local meta = minetest.get_meta(pos)

	if (mesecon.do_overheat(pos)) then
		minetest.remove_node(pos)
		minetest.after(0.2, function (pos)
			mesecon.receptor_off(pos, mesecon.rules.flat)
		end , pos) -- wait for pending parsings
		minetest.add_item(pos, "mesecons_microcontroller:microcontroller0000")
	end

	local code = meta:get_string("code")
	code = yc.code_remove_commentary(code)
	code = string.gsub(code, " ", "")	--Remove all spaces
	code = string.gsub(code, "	", "")	--Remove all tabs
	if yc.parsecode(code, pos) == nil then
		meta:set_string("infotext", S("Code not valid!").."\n"..code)
	else
		meta:set_string("infotext", S("Working Microcontroller").."\n"..code)
	end
end


--Code Parsing
yc.code_remove_commentary = function(code)
	local is_string = false
	for i = 1, #code do
		if code:sub(i, i) == '"' then
			is_string = not is_string --toggle is_string
		elseif code:sub(i, i) == ":" and not is_string then
			return code:sub(1, i-1)
		end
	end
	return code
end

yc.parsecode = function(code, pos)
	local meta = minetest.get_meta(pos)
	local endi = 1
	local Lreal = yc.get_real_portstates(pos)
	local Lvirtual = yc.get_virtual_portstates(pos)
	if Lvirtual == nil then return nil end
	local c
	local eeprom = meta:get_string("eeprom")
	while true do
		local command, params
		command, endi = yc.parse_get_command(code, endi)
		if command == nil then return nil end
		if command == true then break end --end of code
		if command == "if" then
			local r
			r, endi = yc.command_if(code, endi, yc.merge_portstates(Lreal, Lvirtual), eeprom)
			if r == nil then return nil end
			if r == true then  -- nothing
			elseif r == false then
				local endi_new = yc.skip_to_else (code, endi)
				if endi_new == nil then --else > not found
					endi = yc.skip_to_endif(code, endi)
				else
					endi = endi_new
				end
				if endi == nil then return nil end
			end
		else
			params, endi = yc.parse_get_params(code, endi)
			if not params then return nil end
		end
		if command == "on" then
			L = yc.command_on (params, Lvirtual)
		elseif command == "off" then
			L = yc.command_off(params, Lvirtual)
		elseif command == "print" then
			local su = yc.command_print(params, eeprom, yc.merge_portstates(Lreal, Lvirtual))
			if su ~= true then return nil end
		elseif command == "after" then
			local su = yc.command_after(params, pos)
			if su == nil then return nil end
		elseif command == "sbi" then
			local new_eeprom
			new_eeprom, Lvirtual = yc.command_sbi (params, eeprom, yc.merge_portstates(Lreal, Lvirtual), Lvirtual)
			if new_eeprom == nil then return nil
			else eeprom = new_eeprom end
		elseif command == "if" then --nothing
		else
			return nil
		end
		if Lvirtual == nil then return nil end
		if eeprom == nil then return nil else
		minetest.get_meta(pos):set_string("eeprom", eeprom) end
	end
	yc.action(pos, Lvirtual)
	return true
end

yc.parse_get_command = function(code, starti)
	local i = starti
	local s
	while s ~= "" do
		s = string.sub(code, i, i)
		if s == "(" then
			return string.sub(code, starti, i-1), i + 1 -- i: ( i+1 after (
		end
		if s == ";" and starti == i then
			starti = starti + 1
			i = starti
		elseif s == ">" then
			starti = yc.skip_to_endif(code, starti)
			if starti == nil then return nil end
			i = starti
		else
			i = i + 1
		end
	end

	if starti == i-1 then
		return true, true
	end
	return nil, nil
end

yc.parse_get_params = function(code, starti)
	local i = starti
	local s
	local params = {}
	local is_string = false
	while s ~= "" do
		s = string.sub(code, i, i)
		if code:sub(i, i) == '"' then
			is_string = (is_string==false) --toggle is_string
		end
		if s == ")" and is_string == false then
			table.insert(params, string.sub(code, starti, i-1)) -- i: ) i+1 after )
			return params, i + 1
		end
		if s == "," and is_string == false then
			table.insert(params, string.sub(code, starti, i-1)) -- i: ) i+1 after )
			starti = i + 1
		end
		i = i + 1
	end
	return nil, nil
end

yc.parse_get_eeprom_param = function(cond, starti)
	local i = starti
	local s
	local addr
	while s ~= "" do
		s = string.sub(cond, i, i)
		if string.find("0123456789", s) == nil or s == "" then
			addr = string.sub(cond, starti, i-1) -- i: last number i+1 after last number
			return addr, i
		end
		if s == "," then return nil, nil end
		i = i + 1
	end
	return nil, nil
end

yc.skip_to_endif = function(code, starti)
	local i = starti
	local s = false
	local open_ifs = 1
	while s ~= nil and s~= "" do
		s = code:sub(i, i)
		if s == "i" and code:sub(i+1, i+1) == "f" then --if in µCScript
			open_ifs = open_ifs + 1
		end
		if s == ";" then
			open_ifs = open_ifs - 1
		end
		if open_ifs == 0 then
			return i + 1
		end
		i = i + 1
	end
	return nil
end

yc.skip_to_else = function(code, starti)
	local i = starti
	local s = false
	local open_ifs = 1
	while s ~= nil and s~= "" do
		s = code:sub(i, i)
		if s == "i" and code:sub(i+1, i+1) == "f" then --if in µCScript
			open_ifs = open_ifs + 1
		end
		if s == ";" then
			open_ifs = open_ifs - 1
		end
		if open_ifs == 1 and s == ">" then
			return i + 1
		end
		i = i + 1
	end
	return nil
end

--Commands
yc.command_on = function(params, L)
	local rules = {}
	for i, port in ipairs(params) do
		L = yc.set_portstate (port, true, L)
	end
	return L
end

yc.command_off = function(params, L)
	local rules = {}
	for i, port in ipairs(params) do
		L = yc.set_portstate (port, false, L)
	end
	return L
end

yc.command_print = function(params, eeprom, L)
	local s = ""
	for i, param in ipairs(params) do
		if param:sub(1,1) == '"' and param:sub(#param, #param) == '"' then
			s = s..param:sub(2, #param-1)
		else
			r = yc.command_parsecondition(param, L, eeprom)
			if r == "1" or r == "0" then
				s = s..r
			else return nil end
		end
	end
	print(s) --don't remove
	return true
end

yc.command_sbi = function(params, eeprom, L, Lv)
	if params[1]==nil or params[2]==nil or params[3] ~=nil then return nil end
	local status = yc.command_parsecondition(params[2], L, eeprom)

	if status == nil then return nil, nil end

	if string.find("ABCD", params[1])~=nil and #params[1]==1 then --is a port
		if status == "1" then
			Lv = yc.set_portstate (params[1], true,  Lv)
		else
			Lv = yc.set_portstate (params[1], false, Lv)
		end
		return eeprom, Lv;
	end

	--is an eeprom address
	local new_eeprom = "";
	for i=1, #eeprom do
		if tonumber(params[1])==i then
			new_eeprom = new_eeprom..status
		else
			new_eeprom = new_eeprom..eeprom:sub(i, i)
		end
	end
	return new_eeprom, Lv
end

-- after (delay)
yc.command_after = function(params, pos)
	if params[1] == nil or params[2] == nil or params[3] ~= nil then return nil end

	--get time (maximum time is 200)
	local time = tonumber(params[1])
	if time == nil or time > 200 then
		return nil
	end

	--get code in quotes "code"
	if string.sub(params[2], 1, 1) ~= '"' or string.sub(params[2], #params[2], #params[2]) ~= '"' then return nil end
	local code = string.sub(params[2], 2, #params[2] - 1)

	local afterid = math.random(10000)
	local meta = minetest.get_meta(pos)
	meta:set_int("afterid", afterid)
	minetest.after(time, yc.command_after_execute, {pos = pos, code = code, afterid = afterid})
	return true
end

yc.command_after_execute = function(params)
	local meta = minetest.get_meta(params.pos)
	if meta:get_int("afterid") == params.afterid then --make sure the node has not been changed
		if yc.parsecode(params.code, params.pos) == nil then
			meta:set_string("infotext", S("Code in after() not valid!"))
		else
			if code ~= nil then
				meta:set_string("infotext", S("Working Microcontroller").."\n"..code)
			else
				meta:set_string("infotext", S("Working Microcontroller"))
			end
		end
	end
end

--If
yc.command_if = function(code, starti, L, eeprom)
	local cond, endi = yc.command_if_getcondition(code, starti)
	if cond == nil then return nil end

	cond = yc.command_parsecondition(cond, L, eeprom)

	local result
	if cond == "0" then result = false
	elseif cond == "1" then result = true end
	if not result then end
	return result, endi --endi from local cond, endi = yc.command_if_getcondition(code, starti)
end

--Condition parsing
yc.command_if_getcondition = function(code, starti)
	local i = starti
	local s
	local brackets = 1 --1 Bracket to close
	while s ~= "" do
		s = string.sub(code, i, i)

		if s == ")" then
			brackets = brackets - 1
		end

		if s == "(" then
			brackets = brackets + 1
		end

		if brackets == 0 then
			return string.sub(code, starti, i-1), i + 1 -- i: ( i+1 after (
		end

		i = i + 1
	end
	return nil, nil
end

yc.command_parsecondition = function(cond, L, eeprom)
	cond = string.gsub(cond, "A", tonumber(L.a and 1 or 0))
	cond = string.gsub(cond, "B", tonumber(L.b and 1 or 0))
	cond = string.gsub(cond, "C", tonumber(L.c and 1 or 0))
	cond = string.gsub(cond, "D", tonumber(L.d and 1 or 0))


	local i = 1
	local l = string.len(cond)
	while i<=l do
		local s = cond:sub(i,i)
		if s == "#" then
			local addr, endi = yc.parse_get_eeprom_param(cond, i+1)
			local buf = yc.eeprom_read(tonumber(addr), eeprom)
			if buf == nil then return nil end
			local call = cond:sub(i, endi-1)
			cond = string.gsub(cond, call, buf)
			i = 0
			l = string.len(cond)
		end
		i = i + 1
	end

	cond = string.gsub(cond, "!0", "1")
	cond = string.gsub(cond, "!1", "0")

	local i = 2
	local l = string.len(cond)
	while i<=l do
		local s = cond:sub(i,i)
		local b = tonumber(cond:sub(i-1, i-1))
		local a = tonumber(cond:sub(i+1, i+1))
		if cond:sub(i+1, i+1) == nil then break end
		if s == "=" then
			if a==nil then return nil end
			if b==nil then return nil end
			if a == b  then buf = "1" end
			if a ~= b then buf = "0" end
			cond = string.gsub(cond, b..s..a, buf)
			i = 1
			l = string.len(cond)
		end
		i = i + 1
	end

	local i = 2
	local l = string.len(cond)
	while i<=l do
		local s = cond:sub(i,i)
		local b = tonumber(cond:sub(i-1, i-1))
		local a = tonumber(cond:sub(i+1, i+1))
		if cond:sub(i+1, i+1) == nil then break end
		if s == "&" then
			if a==nil then return nil end
			if b==nil then return nil end
			local buf = ((a==1) and (b==1))
			if buf == true  then buf = "1" end
			if buf == false then buf = "0" end
			cond = string.gsub(cond, b..s..a, buf)
			i = 1
			l = string.len(cond)
		end
		if s == "|" then
			if a==nil then return nil end
			if b==nil then return nil end
			local buf = ((a == 1) or (b == 1))
			if buf == true  then buf = "1" end
			if buf == false then buf = "0" end
			cond = string.gsub(cond, b..s..a, buf)
			i = 1
			l = string.len(cond)
		end
		if s == "~" then
			if a==nil then return nil end
			if b==nil then return nil end
			local buf = (((a == 1) or (b == 1)) and not((a==1) and (b==1)))
			if buf == true  then buf = "1" end
			if buf == false then buf = "0" end
			cond = string.gsub(cond, b..s..a, buf)
			i = 1
			l = string.len(cond)
		end
		i = i + 1
	end

	return cond
end

--Virtual-Hardware functions
yc.eeprom_read = function(number, eeprom)
	if not number then return end
	return eeprom:sub(number, number)
end

--Real I/O functions
yc.action = function(pos, L) --L-->Lvirtual
	local Lv = yc.get_virtual_portstates(pos)
	local name = "mesecons_microcontroller:microcontroller"
		..tonumber(L.d and 1 or 0)
		..tonumber(L.c and 1 or 0)
		..tonumber(L.b and 1 or 0)
		..tonumber(L.a and 1 or 0)
	local node = minetest.get_node(pos)
	minetest.swap_node(pos, {name = name, param2 = node.param2})

	yc.action_setports(pos, L, Lv)
end

yc.action_setports = function(pos, L, Lv)
	local name = "mesecons_microcontroller:microcontroller"
	local rules
	if Lv.a ~= L.a then
		rules = microc_rules[name.."0001"]
		if L.a == true then mesecon.receptor_on(pos, rules)
		else mesecon.receptor_off(pos, rules) end
	end
	if Lv.b ~= L.b then
		rules = microc_rules[name.."0010"]
		if L.b == true then mesecon.receptor_on(pos, rules)
		else mesecon.receptor_off(pos, rules) end
	end
	if Lv.c ~= L.c then
		rules = microc_rules[name.."0100"]
		if L.c == true then mesecon.receptor_on(pos, rules)
		else mesecon.receptor_off(pos, rules) end
	end
	if Lv.d ~= L.d then
		rules = microc_rules[name.."1000"]
		if L.d == true then mesecon.receptor_on(pos, rules)
		else mesecon.receptor_off(pos, rules) end
	end
end

yc.set_portstate = function(port, state, L)
	if port == "A" then L.a = state
	elseif port == "B" then L.b = state
	elseif port == "C" then L.c = state
	elseif port == "D" then L.d = state
	else return nil end
	return L
end

yc.update_real_portstates = function(pos, node, rulename, newstate)
	local meta = minetest.get_meta(pos)
	if rulename == nil then
		meta:set_int("real_portstates", 1)
		return
	end
	local n = meta:get_int("real_portstates") - 1
	local L = {}
	for i = 1, 4 do
		L[i] = n%2
		n = math.floor(n/2)
	end
	if rulename.x == nil then
		for _, rname in ipairs(rulename) do
			local port = ({4, 1, nil, 3, 2})[rname.x+2*rname.z+3]
			L[port] = (newstate == "on") and 1 or 0
		end
	else
		local port = ({4, 1, nil, 3, 2})[rulename.x+2*rulename.z+3]
		L[port] = (newstate == "on") and 1 or 0
	end
	meta:set_int("real_portstates", 1 + L[1] + 2*L[2] + 4*L[3] + 8*L[4])
end

yc.get_real_portstates = function(pos) -- determine if ports are powered (by itself or from outside)
	local meta = minetest.get_meta(pos)
	local L = {}
	local n = meta:get_int("real_portstates") - 1
	for _, index in ipairs({"a", "b", "c", "d"}) do
		L[index] = ((n%2) == 1)
		n = math.floor(n/2)
	end
	return L
end

yc.get_virtual_portstates = function(pos) -- portstates according to the name
	local name = minetest.get_node(pos).name
	local b, a = string.find(name, ":microcontroller")
	if a == nil then return nil end
	a = a + 1

	local Lvirtual = {a=false, b=false, c=false, d=false}
	if name:sub(a  , a  ) == "1" then Lvirtual.d = true end
	if name:sub(a+1, a+1) == "1" then Lvirtual.c = true end
	if name:sub(a+2, a+2) == "1" then Lvirtual.b = true end
	if name:sub(a+3, a+3) == "1" then Lvirtual.a = true end
	return Lvirtual
end

yc.merge_portstates = function(Lreal, Lvirtual)
	local L = {a=false, b=false, c=false, d=false}
	if Lvirtual.a or Lreal.a then L.a = true end
	if Lvirtual.b or Lreal.b then L.b = true end
	if Lvirtual.c or Lreal.c then L.c = true end
	if Lvirtual.d or Lreal.d then L.d = true end
	return L
end
