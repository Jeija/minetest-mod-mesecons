local S = minetest.get_translator("mesecons_stickyblocks")

-- Sticky blocks can be used together with pistons or movestones to push / pull
-- structures that are "glued" together using sticky blocks

-- All sides sticky block
minetest.register_node("mesecons_stickyblocks:sticky_block_all", {
	-- TODO: Rename to “All-Faces Sticky Block” when other sticky blocks become available
	description = S("Sticky Block"),
	tiles = {"mesecons_stickyblocks_sticky.png"},
	is_ground_content = false,
	groups = {choppy=3, oddly_breakable_by_hand=2},
	mvps_sticky = function (pos, node)
		local connected = {}
		for _, r in ipairs(mesecon.rules.alldirs) do
			table.insert(connected, vector.add(pos, r))
		end
		return connected
	end,
	sounds = default.node_sound_wood_defaults(),
})
