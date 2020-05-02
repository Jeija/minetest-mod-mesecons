local S = minetest.get_translator("mesecons_delayer")

-- Function that get the input/output rules of the delayer
local delayer_get_output_rules = function(node)
	local rules = {{x = 0, y = 0, z = 1}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local delayer_get_input_rules = function(node)
	local rules = {{x = 0, y = 0, z = -1}}
	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

-- Functions that are called after the delay time

local delayer_activate = function(pos, node)
	local def = minetest.registered_nodes[node.name]
	local time = def.delayer_time
	minetest.swap_node(pos, {name = def.delayer_onstate, param2=node.param2})
	mesecon.queue:add_action(pos, "receptor_on", {delayer_get_output_rules(node)}, time, nil)
end

local delayer_deactivate = function(pos, node)
	local def = minetest.registered_nodes[node.name]
	local time = def.delayer_time
	minetest.swap_node(pos, {name = def.delayer_offstate, param2=node.param2})
	mesecon.queue:add_action(pos, "receptor_off", {delayer_get_output_rules(node)}, time, nil)
end

-- Register the 2 (states) x 4 (delay times) delayers

local delaytime = { 0.1, 0.3, 0.5, 1.0 }

for i = 1, 4 do

local boxes = {
	 { -6/16, -8/16, -6/16, 6/16, -7/16, 6/16 },		-- the main slab

	 { -2/16, -7/16, -4/16, 2/16, -26/64, -3/16 },		-- the jeweled "on" indicator
	 { -3/16, -7/16, -3/16, 3/16, -26/64, -2/16 },
	 { -4/16, -7/16, -2/16, 4/16, -26/64, 2/16 },
	 { -3/16, -7/16,  2/16, 3/16, -26/64, 3/16 },
	 { -2/16, -7/16,  3/16, 2/16, -26/64, 4/16 },

	 { -6/16, -7/16, -6/16, -4/16, -27/64, -4/16 },		-- the timer indicator
	 { -8/16, -8/16, -1/16, -6/16, -7/16, 1/16 },		-- the two wire stubs
	 { 6/16, -8/16, -1/16, 8/16, -7/16, 1/16 }
}

-- Delayer definition defaults
local def = {
	drawtype = "nodebox",
	walkable = true,
	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, -8/16, 8/16, -6/16, 8/16 },
	},
	node_box = {
		type = "fixed",
		fixed = boxes
	},
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	is_ground_content = false,
	delayer_time = delaytime[i],
	sounds = default.node_sound_stone_defaults(),
	on_blast = mesecon.on_blastnode,
	drop = "mesecons_delayer:delayer_off_1",
}

-- Deactivated delayer definition defaults
local off_groups = {bendy=2,snappy=1,dig_immediate=2}
if i > 1 then
	off_groups.not_in_creative_inventory = 1
end

local off_state = {
	description = S("Delayer"),
	tiles = {
		"mesecons_delayer_off_"..tostring(i)..".png",
		"mesecons_delayer_bottom.png",
		"mesecons_delayer_ends_off.png",
		"mesecons_delayer_ends_off.png",
		"mesecons_delayer_sides_off.png",
		"mesecons_delayer_sides_off.png"
	},
	inventory_image = "mesecons_delayer_off_1.png",
	wield_image = "mesecons_delayer_off_1.png",
	groups = off_groups,
	on_punch = function(pos, node, puncher)
		if minetest.is_protected(pos, puncher and puncher:get_player_name()) then
			return
		end

		minetest.swap_node(pos, {
			name = "mesecons_delayer:delayer_off_"..tostring(i % 4 + 1),
			param2 = node.param2
		})
	end,
	delayer_onstate = "mesecons_delayer:delayer_on_"..tostring(i),
	mesecons = {
		receptor =
		{
			state = mesecon.state.off,
			rules = delayer_get_output_rules
		},
		effector =
		{
			rules = delayer_get_input_rules,
			action_on = delayer_activate
		}
	},
}
for k, v in pairs(def) do
	off_state[k] = off_state[k] or v
end
minetest.register_node("mesecons_delayer:delayer_off_"..tostring(i), off_state)

-- Activated delayer definition defaults
local on_state = {
	tiles = {
		"mesecons_delayer_on_"..tostring(i)..".png",
		"mesecons_delayer_bottom.png",
		"mesecons_delayer_ends_on.png",
		"mesecons_delayer_ends_on.png",
		"mesecons_delayer_sides_on.png",
		"mesecons_delayer_sides_on.png"
	},
	groups = {bendy = 2, snappy = 1, dig_immediate = 2, not_in_creative_inventory = 1},
	on_punch = function(pos, node, puncher)
		if minetest.is_protected(pos, puncher and puncher:get_player_name()) then
			return
		end

		minetest.swap_node(pos, {
			name = "mesecons_delayer:delayer_on_"..tostring(i % 4 + 1),
			param2 = node.param2
		})
	end,
	delayer_offstate = "mesecons_delayer:delayer_off_"..tostring(i),
	mesecons = {
		receptor =
		{
			state = mesecon.state.on,
			rules = delayer_get_output_rules
		},
		effector =
		{
			rules = delayer_get_input_rules,
			action_off = delayer_deactivate
		}
	},
}
for k, v in pairs(def) do
	on_state[k] = on_state[k] or v
end
minetest.register_node("mesecons_delayer:delayer_on_"..tostring(i), on_state)

end

minetest.register_craft({
	output = "mesecons_delayer:delayer_off_1",
	recipe = {
		{"mesecons_torch:mesecon_torch_on", "group:mesecon_conductor_craftable", "mesecons_torch:mesecon_torch_on"},
		{"default:cobble","default:cobble", "default:cobble"},
	}
})
