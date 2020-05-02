local S = minetest.get_translator("mesecons_gates")

local nodebox = {
	type = "fixed",
	fixed = {{-8/16, -8/16, -8/16, 8/16, -7/16, 8/16 }},
}

local function gate_rotate_rules(node, rules)
	for rotations = 0, node.param2 - 1 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local function gate_get_output_rules(node)
	return gate_rotate_rules(node, {{x=1, y=0, z=0}})
end

local function gate_get_input_rules_oneinput(node)
	return gate_rotate_rules(node, {{x=-1, y=0, z=0}})
end

local function gate_get_input_rules_twoinputs(node)
	return gate_rotate_rules(node, {{x=0, y=0, z=1, name="input1"},
		{x=0, y=0, z=-1, name="input2"}})
end

local function set_gate(pos, node, state)
	local gate = minetest.registered_nodes[node.name]

	if mesecon.do_overheat(pos) then
		minetest.remove_node(pos)
		mesecon.receptor_off(pos, gate_get_output_rules(node))
		minetest.add_item(pos, gate.drop)
	elseif state then
		minetest.swap_node(pos, {name = gate.onstate, param2=node.param2})
		mesecon.receptor_on(pos, gate_get_output_rules(node))
	else
		minetest.swap_node(pos, {name = gate.offstate, param2=node.param2})
		mesecon.receptor_off(pos, gate_get_output_rules(node))
	end
end

local function update_gate(pos, node, link, newstate)
	local gate = minetest.registered_nodes[node.name]

	if gate.inputnumber == 1 then
		set_gate(pos, node, gate.assess(newstate == "on"))
	elseif gate.inputnumber == 2 then
		local meta = minetest.get_meta(pos)
		meta:set_int(link.name, newstate == "on" and 1 or 0)

		local val1 = meta:get_int("input1") == 1
		local val2 = meta:get_int("input2") == 1
		set_gate(pos, node, gate.assess(val1, val2))
	end
end

local function register_gate(name, inputnumber, assess, recipe, description)
	local get_inputrules = inputnumber == 2 and gate_get_input_rules_twoinputs or
		gate_get_input_rules_oneinput

	if not description then
		description = S("Logic Gate: @1", name)
	end

	local basename = "mesecons_gates:"..name
	mesecon.register_node(basename, {
		description = description,
		inventory_image = "jeija_gate_off.png^jeija_gate_"..name..".png",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		drawtype = "nodebox",
		drop = basename.."_off",
		selection_box = nodebox,
		node_box = nodebox,
		walkable = true,
		sounds = default.node_sound_stone_defaults(),
		assess = assess,
		onstate = basename.."_on",
		offstate = basename.."_off",
		inputnumber = inputnumber,
		after_dig_node = mesecon.do_cooldown,
	},{
		tiles = {"jeija_microcontroller_bottom.png^".."jeija_gate_off.png^"..
			"jeija_gate_"..name..".png"},
		groups = {dig_immediate = 2, overheat = 1},
		mesecons = { receptor = {
			state = "off",
			rules = gate_get_output_rules
		}, effector = {
			rules = get_inputrules,
			action_change = update_gate
		}}
	},{
		tiles = {"jeija_microcontroller_bottom.png^".."jeija_gate_on.png^"..
			"jeija_gate_"..name..".png"},
		groups = {dig_immediate = 2, not_in_creative_inventory = 1, overheat = 1},
		mesecons = { receptor = {
			state = "on",
			rules = gate_get_output_rules
		}, effector = {
			rules = get_inputrules,
			action_change = update_gate
		}}
	})

	minetest.register_craft({output = basename.."_off", recipe = recipe})
end

register_gate("diode", 1, function (input) return input end,
	{{"mesecons:mesecon", "mesecons_torch:mesecon_torch_on", "mesecons_torch:mesecon_torch_on"}},
	S("Diode"))

register_gate("not", 1, function (input) return not input end,
	{{"mesecons:mesecon", "mesecons_torch:mesecon_torch_on", "mesecons:mesecon"}},
	S("NOT Gate"))

register_gate("and", 2, function (val1, val2) return val1 and val2 end,
	{{"mesecons:mesecon", "", ""},
	 {"", "mesecons_materials:silicon", "mesecons:mesecon"},
	 {"mesecons:mesecon", "", ""}},
	S("AND Gate"))

register_gate("nand", 2, function (val1, val2) return not (val1 and val2) end,
	{{"mesecons:mesecon", "", ""},
	 {"", "mesecons_materials:silicon", "mesecons_torch:mesecon_torch_on"},
	 {"mesecons:mesecon", "", ""}},
	S("NAND Gate"))

register_gate("xor", 2, function (val1, val2) return (val1 or val2) and not (val1 and val2) end,
	{{"mesecons:mesecon", "", ""},
	 {"", "mesecons_materials:silicon", "mesecons_materials:silicon"},
	 {"mesecons:mesecon", "", ""}},
	S("XOR Gate"))

register_gate("nor", 2, function (val1, val2) return not (val1 or val2) end,
	{{"mesecons:mesecon", "", ""},
	 {"", "mesecons:mesecon", "mesecons_torch:mesecon_torch_on"},
	 {"mesecons:mesecon", "", ""}},
	S("NOR Gate"))

register_gate("or", 2, function (val1, val2) return (val1 or val2) end,
	{{"mesecons:mesecon", "", ""},
	 {"", "mesecons:mesecon", "mesecons:mesecon"},
	 {"mesecons:mesecon", "", ""}},
	S("OR Gate"))
