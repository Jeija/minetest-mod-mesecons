local S = minetest.get_translator("mesecons_hydroturbine")

local screwdriver_exists = minetest.global_exists("screwdriver")

local function insulated_wire_get_rules(node)
	local rules = 	{{x = 1,  y = 0,  z = 0},
			 {x =-1,  y = 0,  z = 0}}
	if node.param2 == 1 or node.param2 == 3 then
		return mesecon.rotate_rules_right(rules)
	end
	return rules
end

minetest.register_node("mesecons_insulated:insulated_on", {
	drawtype = "nodebox",
	description = S("Straight Insulated Mesecon"),
	tiles = {
		"jeija_insulated_wire_sides_on.png",
		"jeija_insulated_wire_sides_on.png",
		"jeija_insulated_wire_ends_on.png",
		"jeija_insulated_wire_ends_on.png",
		"jeija_insulated_wire_sides_on.png",
		"jeija_insulated_wire_sides_on.png"
	},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	walkable = false,
	sunlight_propagates = true,
	selection_box = {
		type = "fixed",
		fixed = { -16/32, -16/32, -7/32, 16/32, -12/32, 7/32 }
	},
	node_box = {
		type = "fixed",
		-- ±0.001 is to prevent z-fighting
		fixed = { -16/32-0.001, -17/32, -3/32, 16/32+0.001, -13/32, 3/32 }
	},
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	drop = "mesecons_insulated:insulated_off",
	sounds = default.node_sound_defaults(),
	mesecons = {conductor = {
		state = mesecon.state.on,
		offstate = "mesecons_insulated:insulated_off",
		rules = insulated_wire_get_rules
	}},
	on_blast = mesecon.on_blastnode,
	on_rotate = screwdriver_exists and screwdriver.rotate_simple,
})

minetest.register_node("mesecons_insulated:insulated_off", {
	drawtype = "nodebox",
	description = S("Straight Insulated Mesecon"),
	tiles = {
		"jeija_insulated_wire_sides_off.png",
		"jeija_insulated_wire_sides_off.png",
		"jeija_insulated_wire_ends_off.png",
		"jeija_insulated_wire_ends_off.png",
		"jeija_insulated_wire_sides_off.png",
		"jeija_insulated_wire_sides_off.png"
	},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	walkable = false,
	sunlight_propagates = true,
	selection_box = {
		type = "fixed",
		fixed = { -16/32, -16/32, -7/32, 16/32, -12/32, 7/32 }
	},
	node_box = {
		type = "fixed",
		-- ±0.001 is to prevent z-fighting
		fixed = { -16/32-0.001, -17/32, -3/32, 16/32+0.001, -13/32, 3/32 }
	},
	groups = {dig_immediate = 3},
	sounds = default.node_sound_defaults(),
	mesecons = {conductor = {
		state = mesecon.state.off,
		onstate = "mesecons_insulated:insulated_on",
		rules = insulated_wire_get_rules
	}},
	on_blast = mesecon.on_blastnode,
	on_rotate = screwdriver_exists and screwdriver.rotate_simple,
})

minetest.register_craft({
	output = "mesecons_insulated:insulated_off 3",
	recipe = {
		{"mesecons_materials:fiber", "mesecons_materials:fiber", "mesecons_materials:fiber"},
		{"mesecons:wire_00000000_off", "mesecons:wire_00000000_off", "mesecons:wire_00000000_off"},
		{"mesecons_materials:fiber", "mesecons_materials:fiber", "mesecons_materials:fiber"},
	}
})
