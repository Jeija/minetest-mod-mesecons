local selection_box = {
	type = "fixed",
	fixed = { -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 }
}

local nodebox = {
	type = "fixed",
	fixed = {
		{ -8/16, -8/16, -8/16, 8/16, -7/16, 8/16 }, -- bottom slab
		{ -6/16, -7/16, -6/16, 6/16, -6/16, 6/16 }
	},
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

local function gate_get_input_rules(node)
	return gate_rotate_rules(node, {{x=-1, y=0, z=0}})
end

local function start_pulse(pos, node)
	local def = minetest.registered_nodes[node.name]
	if mesecon.do_overheat(pos) then
		minetest.remove_node(pos)
		minetest.add_item(pos, def.drop)
		return
	end
	node.name = def.onstate
	minetest.swap_node(pos, node)
	local rules = gate_get_output_rules(node)
	mesecon.receptor_on(pos, rules)
	mesecon.queue:add_action(pos, "mesecons_digital:pulsar_off", {rules, node.name, 1}, 0)
end

local function end_pulse(pos, rules, nodename, delay)
	if delay ~= 0 then
		mesecon.queue:add_action(pos, "mesecons_digital:pulsar_off", {rules, nodename, delay - 1}, 0)
		return
	end
	local node = minetest.get_node(pos)
	if node.name ~= nodename then return end -- don’t crash if the node was replaced!
	local def = minetest.registered_nodes[node.name]
	node.name = def.offstate
	minetest.swap_node(pos, node)
	mesecon.receptor_off(pos, rules)
end

mesecon.queue:add_function("mesecons_digital:pulsar_off", end_pulse)

local function flip_on(pos, node)
	local def = minetest.registered_nodes[node.name]
	if mesecon.do_overheat(pos) then
		minetest.remove_node(pos)
		minetest.add_item(pos, def.drop)
		return
	end
	node.name = def.onstate
	minetest.swap_node(pos, node)
	local rules = gate_get_output_rules(node)
	mesecon.receptor_on(pos, rules)
end

local function flip_off(pos, node)
	local def = minetest.registered_nodes[node.name]
	if mesecon.do_overheat(pos) then
		minetest.remove_node(pos)
		minetest.add_item(pos, def.drop)
		return
	end
	node.name = def.offstate
	minetest.swap_node(pos, node)
	local rules = gate_get_output_rules(node)
	mesecon.receptor_off(pos, rules)
end

local function register_component(name, effector_off, effector_on, recipe, description)
	local basename = "mesecons_digital:"..name
	mesecon.register_node(basename, {
		description = description,
		inventory_image = "jeija_gate_off.png^mesecons_digital_"..name..".png",
		paramtype = "light",
		paramtype2 = "facedir",
		is_ground_content = false,
		drawtype = "nodebox",
		drop = basename.."_off",
		selection_box = selection_box,
		node_box = nodebox,
		walkable = true,
		sounds = default.node_sound_stone_defaults(),
		onstate = basename.."_on",
		offstate = basename.."_off",
		after_dig_node = mesecon.do_cooldown,
	},{
		tiles = {
			"jeija_microcontroller_bottom.png^".."jeija_gate_off.png^"..
			"jeija_gate_output_off.png^".."mesecons_digital_"..name..".png",
			"jeija_microcontroller_bottom.png^".."jeija_gate_output_off.png^"..
			"[transformFY",
			"jeija_gate_side.png^".."jeija_gate_side_output_off.png",
			"jeija_gate_side.png",
			"jeija_gate_side.png",
			"jeija_gate_side.png"
		},
		groups = {dig_immediate = 2, overheat = 1},
		mesecons = { receptor = {
			state = "off",
			rules = gate_get_output_rules
		}, effector = effector_off
		}
	},{
		tiles = {
			"jeija_microcontroller_bottom.png^".."jeija_gate_on.png^"..
			"jeija_gate_output_on.png^".."mesecons_digital_"..name..".png",
			"jeija_microcontroller_bottom.png^".."jeija_gate_output_on.png^"..
			"[transformFY",
			"jeija_gate_side.png^".."jeija_gate_side_output_on.png",
			"jeija_gate_side.png",
			"jeija_gate_side.png",
			"jeija_gate_side.png"
		},
		groups = {dig_immediate = 2, not_in_creative_inventory = 1, overheat = 1},
		mesecons = { receptor = {
			state = "on",
			rules = gate_get_output_rules
		}, effector = effector_on
		}
	})
	minetest.register_craft({output = basename.."_off", recipe = recipe})
end

register_component("pulsar",
	{ rules = gate_get_input_rules, action_on = start_pulse },
	{ rules = gate_get_input_rules },
	{{"air"}},
	"Pulsar")

register_component("flipflop",
	{ rules = gate_get_input_rules, action_on = flip_on },
	{ rules = gate_get_input_rules, action_on = flip_off },
	{{"air"}},
	"Flip-Flop")
