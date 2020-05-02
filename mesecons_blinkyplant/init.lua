local S = minetest.get_translator("mesecons_blinkyplant")

-- The BLINKY_PLANT

local toggle_timer = function (pos)
	local timer = minetest.get_node_timer(pos)
	if timer:is_started() then
		timer:stop()
	else
		timer:start(mesecon.setting("blinky_plant_interval", 3))
	end
end

local on_timer = function (pos)
	local node = minetest.get_node(pos)
	if(mesecon.flipstate(pos, node) == "on") then
		mesecon.receptor_on(pos)
	else
		mesecon.receptor_off(pos)
	end
	toggle_timer(pos)
end

mesecon.register_node("mesecons_blinkyplant:blinky_plant", {
	description=S("Blinky Plant"),
	drawtype = "plantlike",
	inventory_image = "jeija_blinky_plant_off.png",
	paramtype = "light",
	is_ground_content = false,
	walkable = false,
	sounds = default.node_sound_leaves_defaults(),
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, -0.5+0.7, 0.3},
	},
	on_timer = on_timer,
	on_rightclick = toggle_timer,
	on_construct = toggle_timer
},{
	tiles = {"jeija_blinky_plant_off.png"},
	groups = {dig_immediate=3},
	mesecons = {receptor = { state = mesecon.state.off }}
},{
	tiles = {"jeija_blinky_plant_on.png"},
	groups = {dig_immediate=3, not_in_creative_inventory=1},
	mesecons = {receptor = { state = mesecon.state.on }}
})

minetest.register_craft({
	output = "mesecons_blinkyplant:blinky_plant_off 1",
	recipe = {	{"","group:mesecon_conductor_craftable",""},
			{"","group:mesecon_conductor_craftable",""},
			{"group:sapling","group:sapling","group:sapling"}}
})
