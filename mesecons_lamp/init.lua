-- MESELAMPS
minetest.register_node("mesecons_lamp:lamp_on", {
	drawtype = "nodebox",
	tile_images = {"jeija_meselamp_on.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	legacy_wallmounted = true,
	sunlight_propagates = true,
	walkable = false,
	light_source = LIGHT_MAX,
	node_box = {
		type = "wallmounted",
		wall_top = {-0.3125,0.375,-0.3125,0.3125,0.5,0.3125},
		wall_bottom = {-0.3125,-0.5,-0.3125,0.3125,-0.375,0.3125},
		wall_side = {-0.375,-0.3125,-0.3125,-0.5,0.3125,0.3125},
	},
	selection_box = {
		type = "wallmounted",
		wall_top = {-0.3125,0.375,-0.3125,0.3125,0.5,0.3125},
		wall_bottom = {-0.3125,-0.5,-0.3125,0.3125,-0.375,0.3125},
		wall_side = {-0.375,-0.3125,-0.3125,-0.5,0.3125,0.3125},
	},
	groups = {dig_immediate=3,not_in_creative_inventory=1},
	drop='"mesecons_lamp:lamp_off" 1',
})

minetest.register_node("mesecons_lamp:lamp_off", {
	drawtype = "nodebox",
	tile_images = {"jeija_meselamp_off.png"},
	inventory_image = "jeija_meselamp.png",
	wield_image = "jeija_meselamp.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	node_box = {
		type = "wallmounted",
		wall_top = {-0.3125,0.375,-0.3125,0.3125,0.5,0.3125},
		wall_bottom = {-0.3125,-0.5,-0.3125,0.3125,-0.375,0.3125},
		wall_side = {-0.375,-0.3125,-0.3125,-0.5,0.3125,0.3125},
	},
	selection_box = {
		type = "wallmounted",
		wall_top = {-0.3125,0.375,-0.3125,0.3125,0.5,0.3125},
		wall_bottom = {-0.3125,-0.5,-0.3125,0.3125,-0.375,0.3125},
		wall_side = {-0.375,-0.3125,-0.3125,-0.5,0.3125,0.3125},
	},
	groups = {dig_immediate=3},
    	description="Meselamp",
})

minetest.register_craft({
	output = '"mesecons_lamp:lamp_off" 1',
	recipe = {
		{'', '"default:glass"', ''},
		{'"mesecons:mesecon_off"', '"default:steel_ingot"', '"mesecons:mesecon_off"'},
		{'', '"default:glass"', ''},
	}
})

mesecon:register_on_signal_on(function(pos, node)
	if node.name == "mesecons_lamp:lamp_off" then
		minetest.env:add_node(pos, {name="mesecons_lamp:lamp_on", param2 = node.param2})
		nodeupdate(pos)
	end
end)

mesecon:register_on_signal_off(function(pos, node)
	if node.name == "mesecons_lamp:lamp_on" then
		minetest.env:add_node(pos, {name="mesecons_lamp:lamp_off", param2 = node.param2})
		nodeupdate(pos)
	end
end)