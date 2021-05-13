-- Sticky blocks can be used together with pistons or movestones to push / pull
-- structures that are "glued" together using sticky blocks
	
	-- X sticky block linear
minetest.register_node("mesecons_stickyblocks_linear:sticky_block_x", {
	description = "X Sticky Block",
	drawtype = "nodebox",
	drop = "mesecons_stickyblocks_linear:sticky_block_y",
	paramtype2 = "facedir",
	tiles = {
		"mesecons_stickyblocks_linear.png",
		"mesecons_stickyblocks_linear.png",
		"mesecons_stickyblocks_linear_sticky.png",
		"mesecons_stickyblocks_linear_sticky.png",
		"mesecons_stickyblocks_linear.png",
		"mesecons_stickyblocks_linear.png",
	},                                                                
	is_ground_content = false,
	groups = {choppy = 3, oddly_breakable_by_hand = 2, sticky = 1, not_in_creative_inventory = 1},
	mvps_sticky = function (pos, node)
		local connected = {}
		for _, r in ipairs(mesecon.rules.x) do
			table.insert(connected, vector.add(pos, r))
		end
		return connected
	end,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.375, -0.375, -0.375, 0.375, 0.375, 0.375},
			{0.375, -0.5, -0.5, 0.5, 0.5, 0.5},
			{-0.5, -0.5, -0.5, -0.375, 0.5, 0.5},
		}
	},                                                                
	sounds = default.node_sound_wood_defaults(),
	on_punch = function(pos, node, player, pointed_thing)
		if string.find(player:get_wielded_item():get_name(), "sticky_") then
			minetest.swap_node(pos, {name = "mesecons_stickyblocks_linear:sticky_block_y" })
		end
	end,
	on_rotate = function(pos, node, player, pointed_thing)
			minetest.swap_node(pos, {name = "mesecons_stickyblocks_linear:sticky_block_y" })
			return true
	end,
})
	
	--  Y sticky block
minetest.register_node("mesecons_stickyblocks_linear:sticky_block_y", {
	description = "Linear Sticky Block",
	drawtype = "nodebox",
	paramtype2 = "facedir",
	tiles = {
		"mesecons_stickyblocks_linear_sticky.png",
		"mesecons_stickyblocks_linear_sticky.png",
		"mesecons_stickyblocks_linear.png",
		"mesecons_stickyblocks_linear.png",
		"mesecons_stickyblocks_linear.png",
		"mesecons_stickyblocks_linear.png",
	},
	is_ground_content = false,
	groups = {choppy = 3, oddly_breakable_by_hand = 2, sticky= 1},
	mvps_sticky = function (pos, node)
		local connected = {}
		for _, r in ipairs(mesecon.rules.y) do
			table.insert(connected, vector.add(pos, r))
		end
		return connected
	end,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.375, -0.375, -0.375, 0.375, 0.375, 0.375},
			{-0.5, 0.375, -0.5, 0.5, 0.5, 0.5},
			{-0.5, -0.5, -0.5, 0.5, -0.375, 0.5},
		}
	},                                                                   
	sounds = default.node_sound_wood_defaults(),
	on_punch = function(pos, node, player, pointed_thing)
		if string.find(player:get_wielded_item():get_name(), "sticky_") then
			minetest.swap_node(pos, {name = "mesecons_stickyblocks_linear:sticky_block_z" })
		end
	end,
	on_rotate = function(pos, node, player, pointed_thing)
			minetest.swap_node(pos, {name = "mesecons_stickyblocks_linear:sticky_block_z" })
			return true
	end,
})
	
	--  Z sticky block
minetest.register_node("mesecons_stickyblocks_linear:sticky_block_z", {
	description = "Z Sticky Block",
	drawtype = "nodebox",
	paramtype2 = "facedir",
	drop = "mesecons_stickyblocks_linear:sticky_block_y",
	tiles = {
		"mesecons_stickyblocks_linear.png",
		"mesecons_stickyblocks_linear.png",
		"mesecons_stickyblocks_linear.png",
		"mesecons_stickyblocks_linear.png",
		"mesecons_stickyblocks_linear_sticky.png",
		"mesecons_stickyblocks_linear_sticky.png",
	},                                                                   
	is_ground_content = false,
	groups = {choppy = 3, oddly_breakable_by_hand = 2, sticky = 1, not_in_creative_inventory = 1},
	mvps_sticky = function (pos, node)
		local connected = {}
		for _, r in ipairs(mesecon.rules.z) do
			table.insert(connected, vector.add(pos, r))
		end
		return connected
	end,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.375, -0.375, -0.375, 0.375, 0.375, 0.375},
			{-0.5, -0.5, 0.375, 0.5, 0.5, 0.5},
			{-0.5, -0.5, -0.5, 0.5, 0.5, -0.375},
		}                                                                
	},
	sounds = default.node_sound_wood_defaults(),
	on_punch = function(pos, node, player, pointed_thing)
		if string.find(player:get_wielded_item():get_name(), "sticky_") then
			minetest.swap_node(pos, {name = "mesecons_stickyblocks_linear:sticky_block_x" })
		end
	end,
	on_rotate = function(pos, node, player, pointed_thing)
			minetest.swap_node(pos, {name = "mesecons_stickyblocks_linear:sticky_block_x" })
			return true
	end,
})
	
mesecon.rules.y = {
	{x =  0, y =  1, z =  0},
	{x =  0, y = -1, z =  0},
}

mesecon.rules.x = {
	{x =  1, y =  0, z =  0},
	{x = -1, y =  0, z =  0},
}

mesecon.rules.z = {
	{x =  0, y =  0, z =  1},
	{x =  0, y =  0, z = -1},
}
	
minetest.register_craft({
	output = "mesecons_stickyblocks_linear:sticky_block_y",
	recipe = {
		{"group:wood"},
		{"mesecons_materials:glue"},
	}
})
