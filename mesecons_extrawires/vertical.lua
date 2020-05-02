local S = minetest.get_translator("mesecons_extrawires")

local vertical_box = {
	type = "fixed",
	fixed = {-1/16, -8/16, -1/16, 1/16, 8/16, 1/16}
}

local top_box = {
	type = "fixed",
	fixed = {{-8/16, -8/16, -8/16, 8/16, -7/16, 8/16}}
}

local bottom_box = {
	type = "fixed",
	fixed = {
		{-8/16, -8/16, -8/16, 8/16, -7/16, 8/16},
		{-1/16, -7/16, -1/16, 1/16, 8/16, 1/16},
	}
}

local vertical_rules = {
	{x=0, y=1, z=0},
	{x=0, y=-1, z=0}
}

local top_rules = {
	{x=1,y=0, z=0},
	{x=-1,y=0, z=0},
	{x=0,y=0, z=1},
	{x=0,y=0, z=-1},
	{x=0,y=-1, z=0}
}

local bottom_rules = {
	{x=1, y=0, z=0},
	{x=-1, y=0, z=0},
	{x=0, y=0, z=1},
	{x=0, y=0, z=-1},
	{x=0, y=1, z=0},
	{x=0, y=2, z=0} -- receive power from pressure plate / detector / ... 2 nodes above
}

local vertical_updatepos = function (pos)
	local node = minetest.get_node(pos)
	if minetest.registered_nodes[node.name]
	and minetest.registered_nodes[node.name].is_vertical_conductor then
		local node_above = minetest.get_node(vector.add(pos, vertical_rules[1]))
		local node_below = minetest.get_node(vector.add(pos, vertical_rules[2]))

		local above = minetest.registered_nodes[node_above.name]
			and minetest.registered_nodes[node_above.name].is_vertical_conductor
		local below = minetest.registered_nodes[node_below.name]
			and minetest.registered_nodes[node_below.name].is_vertical_conductor

		mesecon.on_dignode(pos, node)

		-- Always place offstate conductor and let mesecon.on_placenode take care
		local newname = "mesecons_extrawires:vertical_"
		if above and below then -- above and below: vertical mesecon
			newname = newname .. "off"
		elseif above and not below then -- above only: bottom
			newname = newname .. "bottom_off"
		elseif not above and below then -- below only: top
			newname = newname .. "top_off"
		else -- no vertical wire above, no vertical wire below: use bottom
			newname = newname .. "bottom_off"
		end

		minetest.set_node(pos, {name = newname})
		mesecon.on_placenode(pos, {name = newname})
	end
end

local vertical_update = function (pos, node)
	vertical_updatepos(pos) -- this one
	vertical_updatepos(vector.add(pos, vertical_rules[1])) -- above
	vertical_updatepos(vector.add(pos, vertical_rules[2])) -- below
end

-- Vertical wire
mesecon.register_node("mesecons_extrawires:vertical", {
	description = S("Vertical Mesecon"),
	drawtype = "nodebox",
	walkable = false,
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	selection_box = vertical_box,
	node_box = vertical_box,
	is_vertical_conductor = true,
	drop = "mesecons_extrawires:vertical_off",
	after_place_node = vertical_update,
	after_dig_node = vertical_update,
	sounds = default.node_sound_defaults(),
},{
	tiles = {"mesecons_wire_off.png"},
	groups = {dig_immediate=3},
	mesecons = {conductor = {
		state = mesecon.state.off,
		onstate = "mesecons_extrawires:vertical_on",
		rules = vertical_rules,
	}}
},{
	tiles = {"mesecons_wire_on.png"},
	groups = {dig_immediate=3, not_in_creative_inventory=1},
	mesecons = {conductor = {
		state = mesecon.state.on,
		offstate = "mesecons_extrawires:vertical_off",
		rules = vertical_rules,
	}}
})

-- Vertical wire top
mesecon.register_node("mesecons_extrawires:vertical_top", {
	description = S("Vertical Mesecon"),
	drawtype = "nodebox",
	walkable = false,
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	groups = {dig_immediate=3, not_in_creative_inventory=1},
	selection_box = top_box,
	node_box = top_box,
	is_vertical_conductor = true,
	drop = "mesecons_extrawires:vertical_off",
	after_place_node = vertical_update,
	after_dig_node = vertical_update,
	sounds = default.node_sound_defaults(),
},{
	tiles = {"mesecons_wire_off.png"},
	mesecons = {conductor = {
		state = mesecon.state.off,
		onstate = "mesecons_extrawires:vertical_top_on",
		rules = top_rules,
	}}
},{
	tiles = {"mesecons_wire_on.png"},
	mesecons = {conductor = {
		state = mesecon.state.on,
		offstate = "mesecons_extrawires:vertical_top_off",
		rules = top_rules,
	}}
})

-- Vertical wire bottom
mesecon.register_node("mesecons_extrawires:vertical_bottom", {
	description = S("Vertical Mesecon"),
	drawtype = "nodebox",
	walkable = false,
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	selection_box = bottom_box,
	node_box = bottom_box,
	is_vertical_conductor = true,
	drop = "mesecons_extrawires:vertical_off",
	after_place_node = vertical_update,
	after_dig_node = vertical_update,
	sounds = default.node_sound_defaults(),
},{
	tiles = {"mesecons_wire_off.png"},
	mesecons = {conductor = {
		state = mesecon.state.off,
		onstate = "mesecons_extrawires:vertical_bottom_on",
		rules = bottom_rules,
	}}
},{
	tiles = {"mesecons_wire_on.png"},
	mesecons = {conductor = {
		state = mesecon.state.on,
		offstate = "mesecons_extrawires:vertical_bottom_off",
		rules = bottom_rules,
	}}
})

minetest.register_craft({
	output = "mesecons_extrawires:vertical_off 3",
	recipe = {
		{"mesecons:wire_00000000_off"},
		{"mesecons:wire_00000000_off"},
		{"mesecons:wire_00000000_off"}
	}
})

minetest.register_craft({
	output = "mesecons:wire_00000000_off",
	recipe = {{"mesecons_extrawires:vertical_off"}}
})
