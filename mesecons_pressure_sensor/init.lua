local pp_box_off = {
	type = "fixed",
		fixed = {
			{-0.4375, -0.5, -0.4375, -0.375, -0.46875, 0.4375}, -- NodeBox1
			{0.375, -0.5, -0.4375, 0.4375, -0.46875, 0.4375}, -- NodeBox2
			{-0.4375, -0.5, -0.4375, 0.4375, -0.46875, -0.375}, -- NodeBox3
			{-0.4375, -0.5, 0.375, 0.4375, -0.46875, 0.4375}, -- NodeBox4
			--{-0.3125, -0.53125, -0.3125, 0.3125, -0.46875, 0.3125}, -- NodeBox5
			{-0.5, -0.5, -0.5, -0.3125, -0.49375, 0.5}, -- NodeBox6
			{-0.5, -0.5, 0.3125, 0.5, -0.49375, 0.5}, -- NodeBox7
			{0.3125, -0.5, -0.5, 0.5, -0.49375, 0.5}, -- NodeBox8
			{-0.5, -0.5, -0.5, 0.5, -0.49375, -0.3125}, -- NodeBox9
		}
}

local pp_box_on = {
	type = "fixed",
		fixed = {
			{-0.4375, -0.5, -0.4375, -0.375, -0.4875, 0.4375}, -- NodeBox1
			{0.375, -0.5, -0.4375, 0.4375, -0.4875, 0.4375}, -- NodeBox2
			{-0.4375, -0.5, -0.4375, 0.4375, -0.4875, -0.375}, -- NodeBox3
			{-0.4375, -0.5, 0.375, 0.4375, -0.4875, 0.4375}, -- NodeBox4
			--{-0.3125, -0.53125, -0.3125, 0.3125, -0.46875, 0.3125}, -- NodeBox5
			{-0.5, -0.5, -0.5, -0.3125, -0.49375, 0.5}, -- NodeBox6
			{-0.5, -0.5, 0.3125, 0.5, -0.49375, 0.5}, -- NodeBox7
			{0.3125, -0.5, -0.5, 0.5, -0.49375, 0.5}, -- NodeBox8
			{-0.5, -0.5, -0.5, 0.5, -0.49375, -0.3125}, -- NodeBox9
		}
}

local function pp_on_timer(pos, elapsed)
	local node = minetest.get_node(pos)
	local basename = minetest.registered_nodes[node.name].pressureplate_basename

	-- This is a workaround for a strange bug that occurs when the server is started
	-- For some reason the first time on_timer is called, the pos is wrong
	if not basename then return end

	local objs   = minetest.get_objects_inside_radius(pos, 1)
	local two_below = vector.add(pos, vector.new(0, -2, 0))

	if objs[1] == nil and node.name == basename .. "_on" then
		minetest.set_node(pos, {name = basename .. "_off"})
		minetest.sound_play("mesecons_pressure_sensor_off", {pos = pos, max_hear_distance = 20, gain = 0.5,})
		mesecon.receptor_off(pos, mesecon.rules.pplate)
	elseif node.name == basename .. "_off" then
		for k, obj in pairs(objs) do
			local objpos = obj:getpos()
			if objpos.y > pos.y-1 and objpos.y < pos.y then
				minetest.set_node(pos, {name = basename .. "_on"})
				minetest.sound_play("mesecons_pressure_sensor_on", {pos = pos, max_hear_distance = 20, gain = 0.5,})
				mesecon.receptor_on(pos, mesecon.rules.pplate )
			end
		end
	end
	return true
end

-- Register a Pressure Plate
-- offstate:	name of the pressure plate when inactive
-- onstate:	name of the pressure plate when active
-- description:	description displayed in the player's inventory
-- tiles_off:	textures of the pressure plate when inactive
-- tiles_on:	textures of the pressure plate when active
-- image:	inventory and wield image of the pressure plate
-- recipe:	crafting recipe of the pressure plate
-- groups:	groups
-- sounds:	sound table

function mesecon.register_pressure_plate(basename, description, textures_off, textures_on, image_w, image_i, recipe, groups, sounds)
	local groups_off, groups_on
	if not groups then
		groups = {}
	end
	local groups_off = table.copy(groups)
	local groups_on = table.copy(groups)
	groups_on.not_in_creative_inventory = 1

	mesecon.register_node(basename, {
		drawtype = "nodebox",
		inventory_image = image_i,
		wield_image = image_w,
		paramtype = "light",
		is_ground_content = false,
		description = description,
		pressureplate_basename = basename,
		on_timer = pp_on_timer,
		on_construct = function(pos)
			minetest.get_node_timer(pos):start(mesecon.setting("pplate_interval", 0.1))
		end,
		sounds = sounds,
	},{
		mesecons = {receptor = { state = mesecon.state.off, rules = mesecon.rules.pplate }},
		node_box = pp_box_off,
		selection_box = pp_box_off,
		groups = groups_off,
		tiles = textures_off
	},{
		mesecons = {receptor = { state = mesecon.state.on, rules = mesecon.rules.pplate }},
		node_box = pp_box_on,
		selection_box = pp_box_on,
		groups = groups_on,
		tiles = textures_on
	})

	minetest.register_craft({
		output = basename .. "_off",
		recipe = recipe,
	})
end


mesecon.register_pressure_plate(
	"mesecons_pressure_sensor:pressure_sensor",
	"Pressure Sensor",
	{"pressure_sensor_off_b.png","pressure_sensor_off_b.png","pressure_sensor_off_edges.png"},
	{"pressure_sensor_on_b.png","pressure_sensor_on_b.png","pressure_sensor_on_edges.png"},
	"pressure_sensor_wield.png",
	"pressure_sensor_inv.png",
	{{"group:wood", "group:wood"}},
	{ choppy = 3, oddly_breakable_by_hand = 3 },
	default.node_sound_wood_defaults())


