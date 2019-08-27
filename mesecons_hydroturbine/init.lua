-- HYDRO_TURBINE
-- Water turbine:
-- Active if flowing >water< above it
-- (does not work with other liquids)

local function is_flowing_water(pos)
	local name = minetest.get_node(pos).name
	local is_water = minetest.get_item_group(name, "water") > 0
	local is_flowing = minetest.registered_items[name].liquidtype == "flowing"
	return (is_water and is_flowing)
end

minetest.register_node("mesecons_hydroturbine:hydro_turbine_off", {
	drawtype = "mesh",
	mesh = "jeija_hydro_turbine_off.obj",
	tiles = {
		"jeija_hydro_turbine_sides_off.png",
		"jeija_hydro_turbine_top_bottom.png",
		"jeija_hydro_turbine_turbine_top_bottom_off.png",
		"jeija_hydro_turbine_turbine_misc_off.png"
	},
	inventory_image = "jeija_hydro_turbine_inv.png",
	is_ground_content = false,
	wield_scale = {x=0.75, y=0.75, z=0.75},
	groups = {dig_immediate=2},
	description="Water Turbine",
	paramtype = "light",
	selection_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 1.5, 0.5 },
	},
	sounds = default.node_sound_metal_defaults(),
	mesecons = {receptor = {
		state = mesecon.state.off
	}},
	on_blast = mesecon.on_blastnode,
	on_construct = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(1)
	end,
	on_timer = function(pos)
		local waterpos={x=pos.x, y=pos.y+1, z=pos.z}
		if is_flowing_water(waterpos) then
			minetest.set_node(pos, {name="mesecons_hydroturbine:hydro_turbine_on"})
			mesecon.receptor_on(pos)
		end
		return true
	end,
})

minetest.register_node("mesecons_hydroturbine:hydro_turbine_on", {
	drawtype = "mesh",
	is_ground_content = false,
	mesh = "jeija_hydro_turbine_on.obj",
	wield_scale = {x=0.75, y=0.75, z=0.75},
	tiles = {
		"jeija_hydro_turbine_sides_on.png",
		"jeija_hydro_turbine_top_bottom.png",
		{ name = "jeija_hydro_turbine_turbine_top_bottom_on.png",
		    animation = {type = "vertical_frames", aspect_w = 128, aspect_h = 16, length = 1.6} },
		{ name = "jeija_hydro_turbine_turbine_misc_on.png",
		    animation = {type = "vertical_frames", aspect_w = 256, aspect_h = 32, length = 0.4} }
	},
	inventory_image = "jeija_hydro_turbine_inv.png",
	drop = "mesecons_hydroturbine:hydro_turbine_off 1",
	groups = {dig_immediate=2,not_in_creative_inventory=1},
	description="Water Turbine",
	paramtype = "light",
	selection_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -0.5, 0.5, 1.5, 0.5 },
	},
	sounds = default.node_sound_metal_defaults(),
	mesecons = {receptor = {
		state = mesecon.state.on
	}},
	on_blast = mesecon.on_blastnode,
	on_construct = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(1)
	end,
	on_timer = function(pos)
		local waterpos={x=pos.x, y=pos.y+1, z=pos.z}
		if not is_flowing_water(waterpos) then
			minetest.set_node(pos, {name="mesecons_hydroturbine:hydro_turbine_off"})
			mesecon.receptor_off(pos)
		end
		return true
	end,
})

-- LBM to start timers on existing, ABM-driven nodes
minetest.register_lbm({
	name = "mesecons_hydroturbine:timer_init",
	nodenames = {"mesecons_hydroturbine:hydro_turbine_off",
			"mesecons_hydroturbine:hydro_turbine_on"},
	run_at_every_load = false,
	action = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(1)
	end,
})

minetest.register_craft({
	output = "mesecons_hydroturbine:hydro_turbine_off 2",
	recipe = {
	{"","default:stick", ""},
	{"default:stick", "default:steel_ingot", "default:stick"},
	{"","default:stick", ""},
	}
})

