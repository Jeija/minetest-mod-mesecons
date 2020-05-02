local S = minetest.get_translator("mesecons_lightstone")

local lightstone_rules = {
	{x=0,  y=0,  z=-1},
	{x=1,  y=0,  z=0},
	{x=-1, y=0,  z=0},
	{x=0,  y=0,  z=1},
	{x=1,  y=1,  z=0},
	{x=1,  y=-1, z=0},
	{x=-1, y=1,  z=0},
	{x=-1, y=-1, z=0},
	{x=0,  y=1,  z=1},
	{x=0,  y=-1, z=1},
	{x=0,  y=1,  z=-1},
	{x=0,  y=-1, z=-1},
	{x=0,  y=-1, z=0},
}

function mesecon.lightstone_add(name, base_item, texture_off, texture_on, desc)
	if not desc then
		desc = S("Lightstone (@1)", name)
	end
	minetest.register_node("mesecons_lightstone:lightstone_" .. name .. "_off", {
		tiles = {texture_off},
		is_ground_content = false,
		groups = {cracky = 2, mesecon_effector_off = 1, mesecon = 2},
		description = desc,
		sounds = default.node_sound_stone_defaults(),
		mesecons = {effector = {
			rules = lightstone_rules,
			action_on = function (pos, node)
				minetest.swap_node(pos, {name = "mesecons_lightstone:lightstone_" .. name .. "_on", param2 = node.param2})
			end,
		}},
		on_blast = mesecon.on_blastnode,
	})
	minetest.register_node("mesecons_lightstone:lightstone_" .. name .. "_on", {
		tiles = {texture_on},
		is_ground_content = false,
		groups = {cracky = 2, not_in_creative_inventory = 1, mesecon = 2},
		drop = "mesecons_lightstone:lightstone_" .. name .. "_off",
		light_source = minetest.LIGHT_MAX - 2,
		sounds = default.node_sound_stone_defaults(),
		mesecons = {effector = {
			rules = lightstone_rules,
			action_off = function (pos, node)
				minetest.swap_node(pos, {name = "mesecons_lightstone:lightstone_" .. name .. "_off", param2 = node.param2})
			end,
		}},
		on_blast = mesecon.on_blastnode,
	})

	minetest.register_craft({
		output = "mesecons_lightstone:lightstone_" .. name .. "_off",
		recipe = {
			{"",base_item,""},
			{base_item,"default:torch",base_item},
			{"","group:mesecon_conductor_craftable",""}
		}
	})
end


mesecon.lightstone_add("red", "dye:red", "jeija_lightstone_red_off.png", "jeija_lightstone_red_on.png", S("Red Lightstone"))
mesecon.lightstone_add("green", "dye:green", "jeija_lightstone_green_off.png", "jeija_lightstone_green_on.png", S("Green Lightstone"))
mesecon.lightstone_add("blue", "dye:blue", "jeija_lightstone_blue_off.png", "jeija_lightstone_blue_on.png", S("Blue Lightstone"))
mesecon.lightstone_add("gray", "dye:grey", "jeija_lightstone_gray_off.png", "jeija_lightstone_gray_on.png", S("Grey Lightstone"))
mesecon.lightstone_add("darkgray", "dye:dark_grey", "jeija_lightstone_darkgray_off.png", "jeija_lightstone_darkgray_on.png", S("Dark Grey Lightstone"))
mesecon.lightstone_add("yellow", "dye:yellow", "jeija_lightstone_yellow_off.png", "jeija_lightstone_yellow_on.png", S("Yellow Lightstone"))
mesecon.lightstone_add("orange", "dye:orange", "jeija_lightstone_orange_off.png", "jeija_lightstone_orange_on.png", S("Orange Lightstone"))
mesecon.lightstone_add("white", "dye:white", "jeija_lightstone_white_off.png", "jeija_lightstone_white_on.png", S("White Lightstone"))
mesecon.lightstone_add("pink", "dye:pink", "jeija_lightstone_pink_off.png", "jeija_lightstone_pink_on.png", S("Pink Lightstone"))
mesecon.lightstone_add("magenta", "dye:magenta", "jeija_lightstone_magenta_off.png", "jeija_lightstone_magenta_on.png", S("Magenta Lightstone"))
mesecon.lightstone_add("cyan", "dye:cyan", "jeija_lightstone_cyan_off.png", "jeija_lightstone_cyan_on.png", S("Cyan Lightstone"))
mesecon.lightstone_add("violet", "dye:violet", "jeija_lightstone_violet_off.png", "jeija_lightstone_violet_on.png", S("Violet Lightstone"))
