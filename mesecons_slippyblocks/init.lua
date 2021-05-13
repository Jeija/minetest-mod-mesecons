-- Stippy blocks can be used together with pistons or movestones
	
	minetest.register_node("mesecons_slippyblocks:slippy_block", {
	description = "Slippy block)",
	drawtype = "nodebox",
	tiles = {"mesecons_slippyblocks.png"},
	buildable_to = true,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	drop = "mesecons_slippyblocks:slippy_block",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4375, -0.4375, -0.4375, 0.4375, 0.4375, 0.4375}, -- MiddleBox
			{0.4375, 0.4375, -0.5, 0.5, 0.5, 0.5}, -- f1
			{0.4375, -0.5, -0.5, 0.5, -0.4375, 0.5}, -- f2
			{-0.5, 0.4375, -0.5, -0.4375, 0.5, 0.5}, -- f3
			{-0.5, -0.5, -0.5, -0.4375, -0.4375, 0.5}, -- f4
			{-0.5, -0.5, -0.5, 0.5, -0.4375, -0.4375}, -- r1
			{-0.5, 0.4375, -0.5, 0.5, 0.5, -0.4375}, -- r2
			{-0.5, 0.4375, 0.4375, 0.5, 0.5, 0.5}, -- r3
			{-0.5, -0.5, 0.4375, 0.5, -0.4375, 0.5}, -- r4
			{0.4375, -0.5, -0.5, 0.5, 0.5, -0.4375}, -- t1
			{-0.5, -0.5, -0.5, -0.4375, 0.5, -0.4375}, -- t2
			{-0.5, -0.5, 0.4375, -0.4375, 0.5, 0.5}, -- t3
			{0.4375, -0.5, 0.4375, 0.5, 0.5, 0.5}, -- t4
		}
	},
	on_destruct = function(pos)
		minetest.add_item(pos, "mesecons_slippyblocks:slippy_block")
	end,
	--  Swap the node to a normal one while diging or building node.
	on_dig = function(pos, node, player)
			minetest.swap_node(pos, {name = "mesecons_slippyblocks:slippy_block_temp" })
		minetest.node_dig(pos, node, player)
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		minetest.swap_node(pos, {name = "mesecons_slippyblocks:slippy_block_temp" })
		minetest.item_place_node(itemstack, placer, pointed_thing, param2)
		minetest.swap_node(pos, {name = "mesecons_slippyblocks:slippy_block" })
	end,
})

	minetest.register_node("mesecons_slippyblocks:slippy_block_temp", {
	description = "Slippy block)",
	drawtype = "nodebox",
	tiles = {"mesecons_slippyblocks.png"},
	groups = {cracky = 3,oddly_breakable_by_hand = 3, not_in_creative_inventory = 1},
	drop = "mesecons_slippyblocks:slippy_block",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4375, -0.4375, -0.4375, 0.4375, 0.4375, 0.4375}, -- MiddleBox
			{0.4375, 0.4375, -0.5, 0.5, 0.5, 0.5}, -- f1
			{0.4375, -0.5, -0.5, 0.5, -0.4375, 0.5}, -- f2
			{-0.5, 0.4375, -0.5, -0.4375, 0.5, 0.5}, -- f3
			{-0.5, -0.5, -0.5, -0.4375, -0.4375, 0.5}, -- f4
			{-0.5, -0.5, -0.5, 0.5, -0.4375, -0.4375}, -- r1
			{-0.5, 0.4375, -0.5, 0.5, 0.5, -0.4375}, -- r2
			{-0.5, 0.4375, 0.4375, 0.5, 0.5, 0.5}, -- r3
			{-0.5, -0.5, 0.4375, 0.5, -0.4375, 0.5}, -- r4
			{0.4375, -0.5, -0.5, 0.5, 0.5, -0.4375}, -- t1
			{-0.5, -0.5, -0.5, -0.4375, 0.5, -0.4375}, -- t2
			{-0.5, -0.5, 0.4375, -0.4375, 0.5, 0.5}, -- t3
			{0.4375, -0.5, 0.4375, 0.5, 0.5, 0.5}, -- t4
		}
	},

})

