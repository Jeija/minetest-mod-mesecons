--[[ This mod registers 3 nodes:
- One node for the horizontal-facing dropper (mesecons_dropper:dropper)
- One node for the upwards-facing droppers (mesecons_dropper:dropper_up)
- One node for the downwards-facing droppers (mesecons_dropper:dropper_down)

3 node definitions are needed because of the way the textures are defined.
All node definitions share a lot of code, so this is the reason why there
are so many weird tables below.
]]

local S = minetest.get_translator("mesecons_dropper")

-- For after_place_node
local setup_dropper = function(pos)
	-- Set formspec and inventory
	local form = "size[9,8.75]"..
	"list[current_player;main;0,4.5;9,3;9]"..
	"list[current_player;main;0,7.74;9,1;]"..
	"list[current_name;main;3,0.5;3,3;]"..
	"listring[current_name;main]"..
	"listring[current_player;main]"
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", form)
	local inv = meta:get_inventory()
	inv:set_size("main", 9)
end

local orientate_dropper = function(pos, placer)
	-- Not placed by player
	if not placer then return end

	-- Pitch in degrees
	local pitch = placer:get_look_vertical() * (180 / math.pi)

	if pitch > 55 then
		minetest.swap_node(pos, {name="mesecons_dropper:dropper_up"})
	elseif pitch < -55 then
		minetest.swap_node(pos, {name="mesecons_dropper:dropper_down"})
	end
end

local on_rotate
if minetest.get_modpath("screwdriver") then
	on_rotate = screwdriver.rotate_simple
end

-- Shared core definition table
local dropperdef = {
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local meta = minetest.get_meta(pos)
		local meta2 = meta
		meta:from_table(oldmetadata)
		local inv = meta:get_inventory()
		for i=1, inv:get_size("main") do
			local stack = inv:get_stack("main", i)
			if not stack:is_empty() then
				local p = {x=pos.x+math.random(0, 10)/10-0.5, y=pos.y, z=pos.z+math.random(0, 10)/10-0.5}
				minetest.add_item(p, stack)
			end
		end
		meta:from_table(meta2:to_table())
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return count
		end
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	mesecons = {effector = {
		-- Drop random item when triggered
		action_on = function (pos, node)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local droppos
			if node.name == "mesecons_dropper:dropper" then
				droppos  = vector.subtract(pos, minetest.facedir_to_dir(node.param2))
			elseif node.name == "mesecons_dropper:dropper_up" then
				droppos  = {x=pos.x, y=pos.y+1, z=pos.z}
			elseif node.name == "mesecons_dropper:dropper_down" then
				droppos  = {x=pos.x, y=pos.y-1, z=pos.z}
			end
			local dropnode = minetest.get_node(droppos)
			-- Do not drop into solid nodes
			local dropnodedef = minetest.registered_nodes[dropnode.name]
			if dropnodedef.walkable then
				return
			end
			local stacks = {}
			for i=1,inv:get_size("main") do
				local stack = inv:get_stack("main", i)
				if not stack:is_empty() then
					table.insert(stacks, {stack = stack, stackpos = i})
				end
			end
			if #stacks >= 1 then
				local r = math.random(1, #stacks)
				local stack = stacks[r].stack
				local dropitem = ItemStack(stack)
				dropitem:set_count(1)
				local stack_id = stacks[r].stackpos

				-- Drop item
				minetest.add_item(droppos, dropitem)
				stack:take_item()
				inv:set_stack("main", stack_id, stack)
			end
		end,
		rules = mesecon.rules.alldirs,
	}},
	on_rotate = on_rotate,
}

-- Horizontal dropper

local horizontal_def = table.copy(dropperdef)
horizontal_def.description = S("Dropper")
horizontal_def.after_place_node = function(pos, placer, itemstack, pointed_thing)
	setup_dropper(pos)
	orientate_dropper(pos, placer)
end
horizontal_def.tiles = {
	"mesecons_dropper_top.png", "mesecons_dropper_bottom.png",
	"mesecons_dropper_side.png", "mesecons_dropper_side.png",
	"mesecons_dropper_side.png", "mesecons_dropper_front_horizontal.png"
}
horizontal_def.paramtype2 = "facedir"
horizontal_def.groups = {cracky=3, dropper=1}

minetest.register_node("mesecons_dropper:dropper", horizontal_def)

-- Down dropper
local down_def = table.copy(dropperdef)
down_def.description = S("Downwards-Facing Dropper")
down_def.after_place_node = setup_dropper
down_def.tiles = {
	"mesecons_dropper_top.png", "mesecons_dropper_front_vertical.png",
	"mesecons_dropper_side.png", "mesecons_dropper_side.png",
	"mesecons_dropper_side.png", "mesecons_dropper_side.png"
}
down_def.groups = {cracky=3, dropper=1, not_in_creative_inventory=1}
down_def.drop = "mesecons_dropper:dropper"
minetest.register_node("mesecons_dropper:dropper_down", down_def)

-- Up dropper
-- The up dropper is almost identical to the down dropper, it only differs in textures
local up_def = table.copy(down_def)
up_def.description = S("Upwards-Facing Dropper")
up_def.tiles = {
	"mesecons_dropper_front_vertical.png", "mesecons_dropper_bottom.png",
	"mesecons_dropper_side.png", "mesecons_dropper_side.png",
	"mesecons_dropper_side.png", "mesecons_dropper_side.png"
}
minetest.register_node("mesecons_dropper:dropper_up", up_def)



-- Ladies and gentlemen, I present to you: the crafting recipe!
minetest.register_craft({
	output = 'mesecons_dropper:dropper',
	recipe = {
		{"default:cobble", "default:cobble", "default:cobble",},
		{"default:cobble", "", "default:cobble",},
		{"default:cobble", "group:mesecon_conductor_craftable", "default:cobble",},
	}
})

