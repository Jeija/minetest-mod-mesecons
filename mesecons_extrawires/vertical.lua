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

 -- like bottom_box, but mirrored iny y-direction because of wallmounted
local static_middle_box = {
	type = "fixed",
	fixed = {
		{-8/16,  7/16, -8/16, 8/16, 8/16, 8/16},
		{-1/16, -8/16, -1/16, 1/16, 7/16, 1/16},
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

local static_middle_rules = {}
do
	-- not rotated, plate can connect to normal wire
	static_middle_rules[0] = {
		{x=1, y=0, z=0},
		{x=-1, y=0, z=0},
		{x=0, y=0, z=1},
		{x=0, y=0, z=-1},
		{x=0, y=1, z=0},
		{x=0, y=2, z=0}, -- receive power from pressure plate / detector / ... 2 nodes above
		{x=0, y=-1, z=0},
	}

	-- otherwise rotate these rules
	local r = mesecon.rotate_rules_up({
		{x=0, y=1, z=0},
		{x=0, y=2, z=0}, -- receive power from pressure plate / detector / ... 2 nodes above
		{x=0, y=-1, z=0},
	})
	static_middle_rules[1] = mesecon.rotate_rules_up(r)
	static_middle_rules[2] = r
	static_middle_rules[3] = mesecon.rotate_rules_left(mesecon.rotate_rules_left(r))
	static_middle_rules[4] = mesecon.rotate_rules_right(r)
	static_middle_rules[5] = mesecon.rotate_rules_left(r)
end
local function static_middle_rules_get(node)
	return static_middle_rules[node.param2] or {}
end

local function is_dynamic_vertical_wire(node)
	local nodedef = minetest.registered_nodes[node.name]
	return nodedef and nodedef.is_vertical_conductor
end

local function is_vertical_conductor(node)
	if node.name ~= "mesecons_extrawires:vertical_static_middle_off" and
			node.name ~= "mesecons_extrawires:vertical_static_middle_on" then
		return is_dynamic_vertical_wire(node)
	end
	return node.param2 == 0 or node.param2 == 1
end

local function vertical_updatepos(pos)
	local node = minetest.get_node(pos)
	if not is_dynamic_vertical_wire(node) then
		return
	end
	local node_above = minetest.get_node(vector.add(pos, vertical_rules[1]))
	local node_below = minetest.get_node(vector.add(pos, vertical_rules[2]))

	local above = is_vertical_conductor(node_above)
	local below = is_vertical_conductor(node_below)

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

local function vertical_update(pos)
	vertical_updatepos(pos) -- this one
	vertical_updatepos(vector.add(pos, vertical_rules[1])) -- above
	vertical_updatepos(vector.add(pos, vertical_rules[2])) -- below
end

-- Vertical wire
mesecon.register_node("mesecons_extrawires:vertical", {
	description = "Vertical Mesecon",
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
}, {
	tiles = {"mesecons_wire_off.png"},
	groups = {dig_immediate = 3},
	mesecons = {conductor = {
		state = mesecon.state.off,
		onstate = "mesecons_extrawires:vertical_on",
		rules = vertical_rules,
	}}
}, {
	tiles = {"mesecons_wire_on.png"},
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	mesecons = {conductor = {
		state = mesecon.state.on,
		offstate = "mesecons_extrawires:vertical_off",
		rules = vertical_rules,
	}}
})

-- Vertical wire top
mesecon.register_node("mesecons_extrawires:vertical_top", {
	description = "Vertical mesecon",
	drawtype = "nodebox",
	walkable = false,
	paramtype = "light",
	is_ground_content = false,
	sunlight_propagates = true,
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	selection_box = top_box,
	node_box = top_box,
	is_vertical_conductor = true,
	drop = "mesecons_extrawires:vertical_off",
	after_place_node = vertical_update,
	after_dig_node = vertical_update,
	sounds = default.node_sound_defaults(),
}, {
	tiles = {"mesecons_wire_off.png"},
	mesecons = {conductor = {
		state = mesecon.state.off,
		onstate = "mesecons_extrawires:vertical_top_on",
		rules = top_rules,
	}}
}, {
	tiles = {"mesecons_wire_on.png"},
	mesecons = {conductor = {
		state = mesecon.state.on,
		offstate = "mesecons_extrawires:vertical_top_off",
		rules = top_rules,
	}}
})

-- Vertical wire bottom
mesecon.register_node("mesecons_extrawires:vertical_bottom", {
	description = "Vertical mesecon",
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
}, {
	tiles = {"mesecons_wire_off.png", "jeija_insulated_wire_sides_off.png",
		"mesecons_wire_off.png"},
	mesecons = {conductor = {
		state = mesecon.state.off,
		onstate = "mesecons_extrawires:vertical_bottom_on",
		rules = bottom_rules,
	}}
}, {
	tiles = {"mesecons_wire_on.png", "jeija_insulated_wire_sides_on.png",
		"mesecons_wire_on.png"},
	mesecons = {conductor = {
		state = mesecon.state.on,
		offstate = "mesecons_extrawires:vertical_bottom_off",
		rules = bottom_rules,
	}}
})

-- Static vertical wire middle
mesecon.register_node("mesecons_extrawires:vertical_static_middle", {
	description = "Static middle vertical mesecon",
	drawtype = "nodebox",
	walkable = false,
	paramtype = "light",
	paramtype2 = "wallmounted", -- yes, rotatable
	place_param2 = 0, -- but no automatic rotation
	node_placement_prediction = "", -- also no client-side automatic rotation
	is_ground_content = false,
	sunlight_propagates = true,
	selection_box = static_middle_box,
	node_box = static_middle_box,
	after_place_node = vertical_update,
	after_dig_node = vertical_update,
	sounds = default.node_sound_defaults(),
	on_rotate = false,
}, {
	groups = {dig_immediate = 3},
	tiles = {"mesecons_wire_off.png"},
	on_rotate = minetest.global_exists("screwdriver") and function(pos, node, _, mode, _)
		if mode == screwdriver.ROTATE_FACE then -- left click
			node.param2 = node.param2 + 1
		else -- right click
			node.param2 = node.param2 - 1
		end
		node.param2 = node.param2 % 6
		minetest.swap_node(pos, node)
		vertical_update(pos)
		mesecon.on_placenode(pos, node)
		return true
	end,
	mesecons = {conductor = {
		state = mesecon.state.off,
		onstate = "mesecons_extrawires:vertical_static_middle_on",
		rules = static_middle_rules_get,
	}}
}, {
	groups = {dig_immediate = 3, not_in_creative_inventory = 1},
	tiles = {"mesecons_wire_on.png"},
	mesecons = {conductor = {
		state = mesecon.state.on,
		offstate = "mesecons_extrawires:vertical_static_middle_off",
		rules = static_middle_rules_get,
	}}
})


-- crafting
minetest.register_craft({
	output = "mesecons_extrawires:vertical_off 3",
	recipe = {
		{"group:mesecon_conductor_craftable"},
		{"group:mesecon_conductor_craftable"},
		{"group:mesecon_conductor_craftable"},
	}
})

minetest.register_craft({
	output = "mesecons:wire_00000000_off",
	recipe = {{"mesecons_extrawires:vertical_off"}}
})

minetest.register_craft({
	output = "mesecons_extrawires:vertical_static_middle_off 5",
	recipe = {
		{"",                                 "mesecons_extrawires:vertical_off", ""},
		{"",                                 "mesecons_extrawires:vertical_off", ""},
		{"mesecons_extrawires:vertical_off", "mesecons_extrawires:vertical_off", "mesecons_extrawires:vertical_off"}
	}
})

minetest.register_craft({
	output = "mesecons_extrawires:vertical_off",
	recipe = {{"mesecons_extrawires:vertical_static_middle_off"}}
})
