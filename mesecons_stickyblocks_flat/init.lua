-- Sticky blocks can be used together with pistons or movestones to push / pull
-- structures that are "glued" together using sticky blocks

	-- Flat sticky block not Y
minetest.register_node("mesecons_stickyblocks_flat:sticky_block_xz", {
	description = "Flat Sticky Block",
	drawtype = "nodebox",
	paramtype2 = "facedir",
	tiles = {
		"mesecons_stickyblocks_flat.png",
		"mesecons_stickyblocks_flat.png",
		"mesecons_stickyblocks_flat_sticky.png",
		"mesecons_stickyblocks_flat_sticky.png",
		"mesecons_stickyblocks_flat_sticky.png",
		"mesecons_stickyblocks_flat_sticky.png",
	},                                                                
	is_ground_content = false,
	groups = {choppy = 3, oddly_breakable_by_hand = 2, sticky = 1},
	mvps_sticky = function (pos, node)
		local connected = {}
		for _, r in ipairs(mesecon.rules.xz) do
			table.insert(connected, vector.add(pos, r))
		end
		return connected
	end,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4375, -0.4375, -0.4375, 0.4375, 0.4375, 0.4375},
			{-0.5, -0.5, 0.375, 0.5, 0.5, 0.5},
			{-0.5, -0.5, -0.5, 0.5, 0.5, -0.375},
			{-0.5, -0.5, -0.375, -0.375, 0.5, 0.375},
			{0.375, -0.5, -0.5, 0.5, 0.5, 0.5},
		}                                                                
	},
	sounds = default.node_sound_wood_defaults(),
	on_punch = function(pos, node, player, pointed_thing)
		if string.find(player:get_wielded_item():get_name(), "sticky_") then
			minetest.swap_node(pos, {name = "mesecons_stickyblocks_flat:sticky_block_xy" })
		end
	end,
	on_rotate = function(pos, node, player, pointed_thing)
		minetest.swap_node(pos, {name = "mesecons_stickyblocks_flat:sticky_block_xy" })
		return true
	end,
})
	
	-- Flat sticky block not Z
minetest.register_node("mesecons_stickyblocks_flat:sticky_block_xy", {
	description = "Flat XY Sticky Block",
	drawtype = "nodebox",
	paramtype2 = "facedir",
	drop = "mesecons_stickyblocks_flat:sticky_block_xz",
	tiles = { --+Y, -Y, +X, -X, +Z, -Z
		"mesecons_stickyblocks_flat_sticky.png",
		"mesecons_stickyblocks_flat_sticky.png",
		"mesecons_stickyblocks_flat_sticky.png",
		"mesecons_stickyblocks_flat_sticky.png",
		"mesecons_stickyblocks_flat.png",
		"mesecons_stickyblocks_flat.png",
	},                                                                
	is_ground_content = false,
	groups = {choppy = 3, oddly_breakable_by_hand = 2, sticky = 1, not_in_creative_inventory = 1},
	mvps_sticky = function (pos, node)
		local connected = {}
		for _, r in ipairs(mesecon.rules.xy) do
			table.insert(connected, vector.add(pos, r))
		end
		return connected
	end,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4375, -0.4375, -0.4375, 0.4375, 0.4375, 0.4375}, 
			{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5}, 
			{-0.5, 0.375, -0.5, 0.5, 0.5, 0.5},
			{-0.5, -0.375, -0.5, -0.375, 0.375, 0.5},
			{0.375, -0.5, -0.5, 0.5, 0.5, 0.5},
		}
	},                                                            
	sounds = default.node_sound_wood_defaults(),
	on_punch = function(pos, node, player, pointed_thing)
		if string.find(player:get_wielded_item():get_name(), "sticky_") then
			minetest.swap_node(pos, {name = "mesecons_stickyblocks_flat:sticky_block_yz" })
		end
	end,
	on_rotate = function(pos, node, player, pointed_thing)
		minetest.swap_node(pos, {name = "mesecons_stickyblocks_flat:sticky_block_yz" })
		return true
	end,
})
	
	-- Flat sticky block not X
minetest.register_node("mesecons_stickyblocks_flat:sticky_block_yz", {
	description = "Flat YZ Sticky Block",
	drawtype = "nodebox",
	paramtype2 = "facedir",
	drop = "mesecons_stickyblocks_flat:sticky_block_xz",
	tiles = {
		"mesecons_stickyblocks_flat_sticky.png",
		"mesecons_stickyblocks_flat_sticky.png",
		"mesecons_stickyblocks_flat.png",
		"mesecons_stickyblocks_flat.png",
		"mesecons_stickyblocks_flat_sticky.png",
		"mesecons_stickyblocks_flat_sticky.png",
	},                                                                
	is_ground_content = false,
	groups = {choppy = 3, oddly_breakable_by_hand = 2, sticky = 1, not_in_creative_inventory = 1},
	mvps_sticky = function (pos, node)
		local connected = {}
		for _, r in ipairs(mesecon.rules.yz) do
			table.insert(connected, vector.add(pos, r))
		end
		return connected
	end,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4375, -0.4375, -0.4375, 0.4375, 0.4375, 0.4375},
			{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5},
			{-0.5, 0.375, -0.5, 0.5, 0.5, 0.5},
			{-0.5, -0.375, 0.375, 0.5, 0.375, 0.5},
			{-0.5, -0.5, -0.5, 0.5, 0.5, -0.375},
		}
	},                                                                
	sounds = default.node_sound_wood_defaults(),
	on_punch = function(pos, node, player, pointed_thing)
		local wilded_item_nane = player:get_wielded_item():get_name()
		if string.find(player:get_wielded_item():get_name(), "sticky_") then
			minetest.swap_node(pos, {name = "mesecons_stickyblocks_flat:sticky_block_xz" })
		end
	end,
	on_rotate = function(pos, node, player, pointed_thing)
		minetest.swap_node(pos, {name = "mesecons_stickyblocks_flat:sticky_block_xz" })
		return true
	end,
})
	
	
	
mesecon.rules.xz = {
	{x =  1, y = 0, z =  0},
	{x = -1, y = 0, z =  0},
	{x =  0, y = 0, z =  1},
	{x =  0, y = 0, z = -1},
}

mesecon.rules.xy = {
	{x =  1, y =  0, z =  0},
	{x = -1, y =  0, z =  0},
	{x =  0, y =  1, z =  0},
	{x =  0, y = -1, z =  0},
}

mesecon.rules.yz = {
	{x =  0, y =  1, z =  0},
	{x =  0, y = -1, z =  0},
	{x =  0, y =  0, z =  1},
	{x =  0, y =  0, z = -1},
}
	
	
minetest.register_craft({
	output = "mesecons_stickyblocks_flat:sticky_block_xz",
	recipe = {
		{"mesecons_materials:glue","group:wood", "mesecons_materials:glue"},
	}
})

