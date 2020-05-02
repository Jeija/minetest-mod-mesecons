local S = minetest.get_translator("mesecons_extrawires")

local screwdriver_exists = minetest.global_exists("screwdriver")

local tjunction_nodebox = {
	type = "fixed",
	-- ±0.001 is to prevent z-fighting
	fixed = {{ -16/32-0.001, -17/32, -3/32, 16/32+0.001, -13/32, 3/32 },
		 { -3/32, -17/32, -16/32+0.001, 3/32, -13/32, -3/32},}
}

local tjunction_selectionbox = {
		type = "fixed",
		fixed = { -16/32, -16/32, -16/32, 16/32, -12/32, 7/32 },
}

local tjunction_get_rules = function (node)
	local rules =
	{{x = 0,  y = 0,  z =  1},
	 {x = 1,  y = 0,  z =  0},
	 {x = 0,  y = 0,  z = -1}}

	for i = 0, node.param2 do
		rules = mesecon.rotate_rules_left(rules)
	end

	return rules
end

minetest.register_node("mesecons_extrawires:tjunction_on", {
	drawtype = "nodebox",
	tiles = {
		"jeija_insulated_wire_tjunction_tb_on.png",
		"jeija_insulated_wire_tjunction_tb_on.png^[transformR180",
		"jeija_insulated_wire_ends_on.png",
		"jeija_insulated_wire_ends_on.png",
		"jeija_insulated_wire_sides_on.png",
		"jeija_insulated_wire_ends_on.png"
	},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	walkable = false,
	sunlight_propagates = true,
	selection_box = tjunction_selectionbox,
	node_box = tjunction_nodebox,
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	drop = "mesecons_extrawires:tjunction_off",
	sounds = default.node_sound_defaults(),
	mesecons = {conductor =
	{
		state = mesecon.state.on,
		rules = tjunction_get_rules,
		offstate = "mesecons_extrawires:tjunction_off"
	}},
	on_blast = mesecon.on_blastnode,
	on_rotate = screwdriver_exists and screwdriver.rotate_simple,
})

minetest.register_node("mesecons_extrawires:tjunction_off", {
	drawtype = "nodebox",
	description = S("Insulated Mesecon T-junction"),
	tiles = {
		"jeija_insulated_wire_tjunction_tb_off.png",
		"jeija_insulated_wire_tjunction_tb_off.png^[transformR180",
		"jeija_insulated_wire_ends_off.png",
		"jeija_insulated_wire_ends_off.png",
		"jeija_insulated_wire_sides_off.png",
		"jeija_insulated_wire_ends_off.png"
	},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	walkable = false,
	sunlight_propagates = true,
	selection_box = tjunction_selectionbox,
	node_box = tjunction_nodebox,
	groups = {dig_immediate = 3},
	sounds = default.node_sound_defaults(),
	mesecons = {conductor =
	{
		state = mesecon.state.off,
		rules = tjunction_get_rules,
		onstate = "mesecons_extrawires:tjunction_on"
	}},
	on_blast = mesecon.on_blastnode,
	on_rotate = screwdriver_exists and screwdriver.rotate_simple,
})

minetest.register_craft({
	output = "mesecons_extrawires:tjunction_off 3",
	recipe = {
		{"", "", ""},
		{"mesecons_insulated:insulated_off", "mesecons_insulated:insulated_off", "mesecons_insulated:insulated_off"},
		{"", "mesecons_insulated:insulated_off", ""},
	}
})
