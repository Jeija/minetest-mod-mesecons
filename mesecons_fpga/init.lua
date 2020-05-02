local S = minetest.get_translator("mesecons_fpga")
local F = minetest.formspec_escape

local plg = {}
plg.rules = {}
-- per-player formspec positions
plg.open_formspecs = {}

local lcore = dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/logic.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/tool.lua")(plg)

plg.register_nodes = function(template)
	-- each loop is for one of the 4 IO ports
	for a = 0, 1 do
	for b = 0, 1 do
	for c = 0, 1 do
	for d = 0, 1 do
		local ndef = table.copy(template)
		local nodename = "mesecons_fpga:fpga"
				.. tostring(d) .. tostring(c) .. tostring(b) .. tostring(a)

		-- build top texture string
		local texture = "jeija_fpga_top.png"
		if a == 1 then texture = texture .. "^jeija_microcontroller_LED_A.png" end
		if b == 1 then texture = texture .. "^jeija_microcontroller_LED_B.png" end
		if c == 1 then texture = texture .. "^jeija_microcontroller_LED_C.png" end
		if d == 1 then texture = texture .. "^jeija_microcontroller_LED_D.png" end
		ndef.tiles[1] = texture
		ndef.inventory_image = texture

		if (a + b + c + d) > 0 then
			ndef.groups["not_in_creative_inventory"] = 1
		end

		-- interaction with mesecons (input / output)
		local rules_out = {}
		if a == 1 then table.insert(rules_out, {x = -1, y = 0, z =  0}) end
		if b == 1 then table.insert(rules_out, {x =  0, y = 0, z =  1}) end
		if c == 1 then table.insert(rules_out, {x =  1, y = 0, z =  0}) end
		if d == 1 then table.insert(rules_out, {x =  0, y = 0, z = -1}) end
		plg.rules[nodename] = rules_out

		local rules_in = {}
		if a == 0 then table.insert(rules_in, {x = -1, y = 0, z =  0}) end
		if b == 0 then table.insert(rules_in, {x =  0, y = 0, z =  1}) end
		if c == 0 then table.insert(rules_in, {x =  1, y = 0, z =  0}) end
		if d == 0 then table.insert(rules_in, {x =  0, y = 0, z = -1}) end
		ndef.mesecons.effector.rules = rules_in

		if (a + b + c + d) > 0 then
			ndef.mesecons.receptor = {
				state = mesecon.state.on,
				rules = rules_out,
			}
		end

		minetest.register_node(nodename, ndef)
	end
	end
	end
	end
end

plg.register_nodes({
	description = S("FPGA"),
	drawtype = "nodebox",
	tiles = {
		"", -- replaced later
		"jeija_microcontroller_bottom.png",
		"jeija_fpga_sides.png",
		"jeija_fpga_sides.png",
		"jeija_fpga_sides.png",
		"jeija_fpga_sides.png"
	},
	inventory_image = "", -- replaced later
	is_ground_content = false,
	sunlight_propagates = true,
	paramtype = "light",
	walkable = true,
	groups = {dig_immediate = 2, mesecon = 3, overheat = 1},
	drop = "mesecons_fpga:fpga0000",
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
		local is = { {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }

		meta:set_string("instr", lcore.serialize(is))
		meta:set_int("valid", 0)
		meta:set_string("infotext", S("FPGA"))
	end,
	on_rightclick = function(pos, node, clicker)
		if not minetest.is_player(clicker) then
			return
		end
		local meta = minetest.get_meta(pos)
		local name = clicker:get_player_name()
		-- Erase formspecs of old FPGAs
		meta:set_string("formspec", "")

		plg.open_formspecs[name] = pos
		local is = lcore.deserialize(meta:get_string("instr"))
		minetest.show_formspec(name, "mesecons:fpga", plg.to_formspec_string(is, nil))
	end,
	sounds = default.node_sound_stone_defaults(),
	mesecons = {
		effector = {
			rules = {}, -- replaced later
			action_change = function(pos, node, rule, newstate)
				plg.ports_changed(pos, rule, newstate)
				plg.update(pos)
			end
		}
	},
	after_dig_node = function(pos, node)
		mesecon.receptor_off(pos, plg.rules[node.name])
		for name, open_pos in pairs(plg.open_formspecs) do
			if vector.equals(pos, open_pos) then
				minetest.close_formspec(name, "mesecons:fpga")
				plg.open_formspecs[name] = nil
			end
		end
	end,
	on_blast = mesecon.on_blastnode,
	on_rotate = function(pos, node, user, mode)
		local abcd1 = {"A", "B", "C", "D"}
		local abcd2 = {A = 1, B = 2, C = 3, D = 4}
		local ops = {"op1", "op2", "dst"}
		local dir = 0
		if mode == screwdriver.ROTATE_FACE then -- clock-wise
			dir = 1
			if user and user:is_player() then
				minetest.chat_send_player(user:get_player_name(),
						S("FPGA ports have been rotated clockwise."))
			end
		elseif mode == screwdriver.ROTATE_AXIS then -- counter-clockwise
			dir = -1
			if user and user:is_player() then
				minetest.chat_send_player(user:get_player_name(),
						S("FPGA ports have been rotated counter-clockwise."))
			end
		end

		local meta = minetest.get_meta(pos)
		local instr = lcore.deserialize(meta:get_string("instr"))
		for i = 1, #instr do
			for _, op in ipairs(ops) do
				local o = instr[i][op]
				if o and o.type == "io" then
					local num = abcd2[o.port]
					num = num + dir
					if num > 4 then num = 1
					elseif num < 1 then num = 4 end
					instr[i][op].port = abcd1[num]
				end
			end
		end

		meta:set_string("instr", lcore.serialize(instr))
		plg.update_meta(pos, instr)
		return true
	end,
})

plg.to_formspec_string = function(is, err)
	local function dropdown_op(x, y, name, val)
		local s = "dropdown[" .. tostring(x) .. "," .. tostring(y) .. ";"
				.. "0.75,0.5;" .. name .. ";" -- the height seems to be ignored?
		s = s .. " ,A,B,C,D,0,1,2,3,4,5,6,7,8,9;"
		if val == nil then
			s = s .. "0" -- actually selects no field at all
		elseif val.type == "io" then
			local mapping = {
				["A"] = 1,
				["B"] = 2,
				["C"] = 3,
				["D"] = 4,
			}
			s = s .. tostring(1 + mapping[val.port])
		else -- "reg"
			s = s .. tostring(6 + val.n)
		end
		return s .. "]"
	end
	local function dropdown_action(x, y, name, val)
		local selected = 0
		local titles = { " " }
		for i, data in ipairs(lcore.get_operations()) do
			titles[i + 1] = data.fs_name
			if val == data.gate then
				selected = i + 1
			end
		end
		return ("dropdown[%f,%f;1.125,0.5;%s;%s;%i]"):format(
			x, y, name, table.concat(titles, ","), selected)
	end
	local s = "size[9,9]"..
		"label[3.4,-0.15;"..F(S("FPGA gate configuration")).."]"..
		"button[7,7.5;2,2.5;program;"..F(S("Program")).."]"..
		"box[4.2,0.5;0.03,7;#ffffff]"..
		"label[0.25,0.25;"..F(S("op. 1")).."]"..
		"label[1.0,0.25;"..F(S("gate type")).."]"..
		"label[2.125,0.25;"..F(S("op. 2")).."]"..
		"label[3.15,0.25;"..F(S("dest")).."]"..
		"label[4.5,0.25;"..F(S("op. 1")).."]"..
		"label[5.25,0.25;"..F(S("gate type")).."]"..
		"label[6.375,0.25;"..F(S("op. 2")).."]"..
		"label[7.4,0.25;"..F(S("dest")).."]"
	local x = 1 - 0.75
	local y = 1 - 0.25
	for i = 1, 14 do
		local cur = is[i]
		s = s .. dropdown_op    (x      , y, tostring(i).."op1", cur.op1)
		s = s .. dropdown_action(x+0.75 , y, tostring(i).."act", cur.action)
		s = s .. dropdown_op    (x+1.875, y, tostring(i).."op2", cur.op2)
		s = s .. "label[" .. tostring(x+2.625) .. "," .. tostring(y+0.1) .. "; ->]"
		s = s .. dropdown_op    (x+2.9  , y, tostring(i).."dst", cur.dst)
		y = y + 1

		if i == 7 then
			x = 4.5
			y = 1 - 0.25
		end
	end
	if err then
		local fmsg = minetest.colorize("#ff0000", minetest.formspec_escape(err.msg))
		s = s .. plg.red_box_around(err.i) ..
			"label[0.25,8.25;"..F(S("The gate configuration is erroneous in the marked area:")).."]"..
			"label[0.25,8.5;" .. fmsg .. "]"
	end
	return s
end

plg.from_formspec_fields = function(fields)
	local function read_op(s)
		if s == nil or s == " " then
			return nil
		elseif s == "A" or s == "B" or s == "C" or s == "D" then
			return {type = "io", port = s}
		else
			return {type = "reg", n = tonumber(s)}
		end
	end
	local function read_action(s)
		for i, data in ipairs(lcore.get_operations()) do
			if data.fs_name == s then
				return data.gate
			end
		end
	end
	local is = {}
	for i = 1, 14 do
		local cur = {}
		cur.op1 = read_op(fields[tonumber(i) .. "op1"])
		cur.action = read_action(fields[tonumber(i) .. "act"])
		cur.op2 = read_op(fields[tonumber(i) .. "op2"])
		cur.dst = read_op(fields[tonumber(i) .. "dst"])
		is[#is + 1] = cur
	end
	return is
end

plg.update_meta = function(pos, is)
	if type(is) == "string" then -- serialized string
		is = lcore.deserialize(is)
	end
	local meta = minetest.get_meta(pos)

	local err = lcore.validate(is)
	if err == nil then
		meta:set_int("valid", 1)
		meta:set_string("infotext", S("FPGA (functional)"))
	else
		meta:set_int("valid", 0)
		meta:set_string("infotext", S("FPGA"))
	end

	-- reset ports and run programmed logic
	plg.setports(pos, false, false, false, false)
	plg.update(pos)

	-- Refresh open formspecs
	local form = plg.to_formspec_string(is, err)
	for name, open_pos in pairs(plg.open_formspecs) do
		if vector.equals(pos, open_pos) then
			minetest.show_formspec(name, "mesecons:fpga", form)
		end
	end
	return err
end

plg.red_box_around = function(i)
	local x, y
	if i > 7 then
		x = 4.5
		y = 0.75 + (i - 8)
	else
		x = 0.25
		y = 0.75 + (i - 1)
	end
	return string.format("box[%f,%f;3.8,0.8;#ff0000]", x-0.1, y-0.05)
end


plg.update = function(pos)
	local meta = minetest.get_meta(pos)
	if meta:get_int("valid") ~= 1 then
		return
	elseif mesecon.do_overheat(pos) then
		plg.setports(pos, false, false, false, false)
		meta:set_int("valid", 0)
		meta:set_string("infotext", S("FPGA (overheated)"))
		return
	end

	local is = lcore.deserialize(meta:get_string("instr"))
	local A, B, C, D = plg.getports(pos)
	A, B, C, D = lcore.interpret(is, A, B, C, D)
	plg.setports(pos, A, B, C, D)
end

plg.ports_changed = function(pos, rule, newstate)
	if rule == nil then return end
	local meta = minetest.get_meta(pos)
	local states

	local s = meta:get_string("portstates")
	if s == nil then
		states = {false, false, false, false}
	else
		states = {
			s:sub(1, 1) == "1",
			s:sub(2, 2) == "1",
			s:sub(3, 3) == "1",
			s:sub(4, 4) == "1",
		}
	end

	-- trick to transform rules (see register_node) into port number
	local portno = ({4, 1, nil, 3, 2})[3 + rule.x + 2*rule.z]
	states[portno] = (newstate == "on")

	meta:set_string("portstates",
			(states[1] and "1" or "0") .. (states[2] and "1" or "0") ..
			(states[3] and "1" or "0") .. (states[4] and "1" or "0")
	)
end

plg.getports = function(pos) -- gets merged states of INPUT & OUTPUT
	local sin, sout

	local s = minetest.get_meta(pos):get_string("portstates")
	if s == nil then
		sin = {false, false, false, false}
	else
		sin = {
			s:sub(1, 1) == "1",
			s:sub(2, 2) == "1",
			s:sub(3, 3) == "1",
			s:sub(4, 4) == "1",
		}
	end

	local name = minetest.get_node(pos).name
	assert(name:find("mesecons_fpga:fpga") == 1)
	local off = #"mesecons_fpga:fpga"
	sout = {
		name:sub(off+4, off+4) == "1",
		name:sub(off+3, off+3) == "1",
		name:sub(off+2, off+2) == "1",
		name:sub(off+1, off+1) == "1",
	}

	return unpack({
		sin[1] or sout[1],
		sin[2] or sout[2],
		sin[3] or sout[3],
		sin[4] or sout[4],
	})
end

plg.setports = function(pos, A, B, C, D) -- sets states of OUTPUT
	local base = "mesecons_fpga:fpga"

	local name = base
			.. (D and "1" or "0") .. (C and "1" or "0")
			.. (B and "1" or "0") .. (A and "1" or "0")
	minetest.swap_node(pos, {name = name, param2 = minetest.get_node(pos).param2})

	if A ~= nil then
		local ru = plg.rules[base .. "0001"]
		if A then mesecon.receptor_on(pos, ru) else mesecon.receptor_off(pos, ru) end
	end
	if B ~= nil then
		local ru = plg.rules[base .. "0010"]
		if B then mesecon.receptor_on(pos, ru) else mesecon.receptor_off(pos, ru) end
	end
	if C ~= nil then
		local ru = plg.rules[base .. "0100"]
		if C then mesecon.receptor_on(pos, ru) else mesecon.receptor_off(pos, ru) end
	end
	if D ~= nil then
		local ru = plg.rules[base .. "1000"]
		if D then mesecon.receptor_on(pos, ru) else mesecon.receptor_off(pos, ru) end
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local player_name = player:get_player_name()

	if formname ~= "mesecons:fpga" or fields.quit then
		plg.open_formspecs[player_name] = nil -- potential garbage
		return
	end
	if not fields.program then
		return -- we only care when the user clicks "Program"
	end
	local pos = plg.open_formspecs[player_name]
	if minetest.is_protected(pos, player_name) then
		minetest.record_protection_violation(pos, player_name)
		return
	end

	local meta = minetest.get_meta(pos)
	local is = plg.from_formspec_fields(fields)

	meta:set_string("instr", lcore.serialize(is))
	local err = plg.update_meta(pos, is)

	if not err then
		plg.open_formspecs[player_name] = nil
		-- Close on success
		minetest.close_formspec(player_name, "mesecons:fpga")
	end
end)

minetest.register_on_leaveplayer(function(player)
	plg.open_formspecs[player:get_player_name()] = nil
end)

minetest.register_craft({
	output = "mesecons_fpga:fpga0000 2",
	recipe = {
		{'group:mesecon_conductor_craftable', 'group:mesecon_conductor_craftable'},
		{'mesecons_materials:silicon', 'mesecons_materials:silicon'},
		{'group:mesecon_conductor_craftable', 'group:mesecon_conductor_craftable'},
	}
})
