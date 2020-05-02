local S = minetest.get_translator("mesecons_button")

-- WALL BUTTON
-- A button that when pressed emits power for 1 second
-- and then turns off again

mesecon.button_turnoff = function (pos)
	local node = minetest.get_node(pos)
	if node.name ~= "mesecons_button:button_on" then -- has been dug
		return
	end
	minetest.swap_node(pos, {name = "mesecons_button:button_off", param2 = node.param2})
	minetest.sound_play("mesecons_button_pop", {pos = pos})
	local rules = mesecon.rules.buttonlike_get(node)
	mesecon.receptor_off(pos, rules)
end

minetest.register_node("mesecons_button:button_off", {
	drawtype = "nodebox",
	tiles = {
	"jeija_wall_button_sides.png",
	"jeija_wall_button_sides.png",
	"jeija_wall_button_sides.png",
	"jeija_wall_button_sides.png",
	"jeija_wall_button_sides.png",
	"jeija_wall_button_off.png"
	},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	legacy_wallmounted = true,
	walkable = false,
	on_rotate = mesecon.buttonlike_onrotate,
	sunlight_propagates = true,
	selection_box = {
	type = "fixed",
		fixed = { -6/16, -6/16, 5/16, 6/16, 6/16, 8/16 }
	},
	node_box = {
		type = "fixed",
		fixed = {
		{ -6/16, -6/16, 6/16, 6/16, 6/16, 8/16 },	-- the thin plate behind the button
		{ -4/16, -2/16, 4/16, 4/16, 2/16, 6/16 }	-- the button itself
	}
	},
	groups = {dig_immediate=2, mesecon_needs_receiver = 1},
	description = S("Button"),
	on_rightclick = function (pos, node)
		minetest.swap_node(pos, {name = "mesecons_button:button_on", param2=node.param2})
		mesecon.receptor_on(pos, mesecon.rules.buttonlike_get(node))
		minetest.sound_play("mesecons_button_push", {pos=pos})
		minetest.get_node_timer(pos):start(1)
	end,
	sounds = default.node_sound_stone_defaults(),
	mesecons = {receptor = {
		state = mesecon.state.off,
		rules = mesecon.rules.buttonlike_get
	}},
	on_blast = mesecon.on_blastnode,
})

minetest.register_node("mesecons_button:button_on", {
	drawtype = "nodebox",
	tiles = {
		"jeija_wall_button_sides.png",
		"jeija_wall_button_sides.png",
		"jeija_wall_button_sides.png",
		"jeija_wall_button_sides.png",
		"jeija_wall_button_sides.png",
		"jeija_wall_button_on.png"
		},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	legacy_wallmounted = true,
	walkable = false,
	on_rotate = false,
	light_source = minetest.LIGHT_MAX-7,
	sunlight_propagates = true,
	selection_box = {
		type = "fixed",
		fixed = { -6/16, -6/16, 5/16, 6/16, 6/16, 8/16 }
	},
	node_box = {
	type = "fixed",
	fixed = {
		{ -6/16, -6/16,  6/16, 6/16, 6/16, 8/16 },
		{ -4/16, -2/16, 11/32, 4/16, 2/16, 6/16 }
	}
    },
	groups = {dig_immediate=2, not_in_creative_inventory=1, mesecon_needs_receiver = 1},
	drop = 'mesecons_button:button_off',
	description = S("Button"),
	sounds = default.node_sound_stone_defaults(),
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = mesecon.rules.buttonlike_get
	}},
	on_timer = mesecon.button_turnoff,
	on_blast = mesecon.on_blastnode,
})

minetest.register_craft({
	output = "mesecons_button:button_off 2",
	recipe = {
		{"group:mesecon_conductor_craftable","default:stone"},
	}
})
