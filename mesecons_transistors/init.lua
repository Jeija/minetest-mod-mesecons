local node_box = {
	type = "fixed",
	fixed = {
		{-8/16, -8/16, -8/16, 8/16, -7/16, 8/16},
	},
}

local function rotate_rules(node, rules)
	for rotations = 0, node.param2 - 1 do
		rules = mesecon.rotate_rules_left(rules)
	end
	return rules
end

local function get_switcher_inputrules(node)
	return rotate_rules(node, {{x = 0, y = 0, z = -1}, {x = 1, y = 0, z = 0},
			{x = -1, y = 0, z = 0}})
end

local function get_conductorrules(node)
	return rotate_rules(node, {{x = 1, y = 0, z = 0}, {x = -1, y = 0, z = 0}})
end

local function get_dir_to_switcher(node)
	return rotate_rules(node, {{x = 0, y = 0, z = -1}})[1]
end

local function get_dir_to_switched(node)
	return rotate_rules(node, {{x = 0, y = 0, z = 1}})[1]
end

local is_transistor_node = {
	["mesecons_transistors:normally_open_contact_open"] = true,
	["mesecons_transistors:normally_open_contact_closed_off" ] = true,
	["mesecons_transistors:normally_open_contact_closed_on" ] = true,
	["mesecons_transistors:normally_closed_contact_open" ] = true,
	["mesecons_transistors:normally_closed_contact_closed_off"] = true,
	["mesecons_transistors:normally_closed_contact_closed_on"] = true,
}

local function handle_overheat(pos, node)
	local conductor_pos = vector.add(pos, get_dir_to_switched(node))
	local conductor_node = mesecon.get_node_force(conductor_pos)

	if not conductor_node or conductor_node.param2 ~= node.param2 or
			not is_transistor_node[conductor_node.name] then
		minetest.remove_node(pos)
		mesecon.on_dignode(pos, node)
		return
	end

	minetest.remove_node(pos)
	minetest.remove_node(conductor_pos)

	mesecon.on_dignode(pos, node)
	mesecon.on_dignode(conductor_pos, conductor_node)

	minetest.add_item(conductor_pos, minetest.registered_nodes[conductor_node.name].drop)
end

local function switcher_on(pos, node)
	if mesecon.do_overheat(pos) then
		handle_overheat(pos, node)
		return
	end

	node.name = "mesecons_transistors:switcher_on"
	minetest.swap_node(pos, node)

	local dir = get_dir_to_switched(node)
	local switched_pos = vector.add(pos, dir)
	local switched_node = mesecon.get_node_force(switched_pos)
	if not switched_node then
		return
	end
	local old_switched_node = {name = switched_node.name, param1 = switched_node.param1,
			param2 = switched_node.param2}

	if switched_node.name == "mesecons_transistors:normally_open_contact_open" then
		switched_node.name = "mesecons_transistors:normally_open_contact_closed_off"
	elseif switched_node.name == "mesecons_transistors:normally_closed_contact_closed_off" or
			switched_node.name == "mesecons_transistors:normally_closed_contact_closed_on" then
		switched_node.name = "mesecons_transistors:normally_closed_contact_open"
	else
		minetest.log("info", "invalid mesecons_transistors:swicher was triggered at "
				.. minetest.pos_to_string(pos) .. ", node at front is " .. switched_node.name)
		return
	end
	if old_switched_node.param2 ~= node.param2 then
		minetest.log("info", "invalid mesecons_transistors:swicher was triggered at "
				.. minetest.pos_to_string(pos) .. ", node at front is from another switcher")
		return
	end

	minetest.swap_node(switched_pos, switched_node)
	mesecon.on_dignode(switched_pos, old_switched_node)
	mesecon.on_placenode(switched_pos, switched_node)
end

local function switcher_off(pos, node)
	if mesecon.do_overheat(pos) then
		handle_overheat(pos, node)
		return
	end

	node.name = "mesecons_transistors:switcher_off"
	minetest.swap_node(pos, node)

	local dir = get_dir_to_switched(node)
	local switched_pos = vector.add(pos, dir)
	local switched_node = mesecon.get_node_force(switched_pos)
	if not switched_node then
		return
	end
	local old_switched_node = {name = switched_node.name, param1 = switched_node.param1,
			param2 = switched_node.param2}

	if switched_node.name == "mesecons_transistors:normally_open_contact_closed_off" or
			switched_node.name == "mesecons_transistors:normally_open_contact_closed_on" then
		switched_node.name = "mesecons_transistors:normally_open_contact_open"
	elseif switched_node.name == "mesecons_transistors:normally_closed_contact_open" then
		switched_node.name = "mesecons_transistors:normally_closed_contact_closed_off"
	else
		minetest.log("info", "invalid mesecons_transistors:swicher was triggered at "
				.. minetest.pos_to_string(pos) .. ", node at front is " .. switched_node.name)
		return
	end
	if old_switched_node.param2 ~= node.param2 then
		minetest.log("info", "invalid mesecons_transistors:swicher was triggered at "
				.. minetest.pos_to_string(pos) .. ", node at front is from another switcher")
		return
	end

	minetest.swap_node(switched_pos, switched_node)
	mesecon.on_dignode(switched_pos, old_switched_node)
	mesecon.on_placenode(switched_pos, switched_node)
end

local function do_nothing()
	-- nothing
end

-- returns a fuction for on_place
-- does pretty much the same as minetest.item_place, but also places the switcher
local function get_on_place_callback(is_nc)
	return function(itemstack, placer, pointed_thing)
		-- Call on_rightclick if the pointed node defines it
		if pointed_thing.type == "node" and placer and
				not placer:get_player_control().sneak then
			local n = minetest.get_node(pointed_thing.under)
			local nn = n.name
			if minetest.registered_nodes[nn] and minetest.registered_nodes[nn].on_rightclick then
				return minetest.registered_nodes[nn].on_rightclick(pointed_thing.under, n,
						placer, itemstack, pointed_thing) or itemstack
			end
		end

		if pointed_thing.type ~= "node" then
			return itemstack
		end

		local nodename = is_nc and "mesecons_transistors:normally_closed_contact_closed_off" or
				"mesecons_transistors:normally_open_contact_open"

		local under = pointed_thing.under
		local oldnode_under = minetest.get_node_or_nil(under)
		local above = pointed_thing.above
		local oldnode_above = minetest.get_node_or_nil(above)
		local playername = placer and placer:get_player_name() or ""
		local log = playername ~= "" and minetest.log or do_nothing

		if not oldnode_under or not oldnode_above then
			log("info", playername .. " tried to place"
				.. " node in unloaded position " .. minetest.pos_to_string(above))
			return itemstack
		end

		local olddef_under = minetest.registered_nodes[oldnode_under.name]
		olddef_under = olddef_under or minetest.nodedef_default
		local olddef_above = minetest.registered_nodes[oldnode_above.name]
		olddef_above = olddef_above or minetest.nodedef_default

		if not olddef_above.buildable_to and not olddef_under.buildable_to then
			log("info", playername .. " tried to place node in invalid position " ..
					minetest.pos_to_string(above) .. ", replacing " ..
					oldnode_above.name)
			return itemstack
		end

		-- Place above pointed node
		local place_to = vector.new(above)
		local oldnode = oldnode_above

		-- If node under is buildable_to, place into it instead (eg. snow)
		if olddef_under.buildable_to then
			log("info", "node under is buildable to")
			place_to = vector.new(under)
			oldnode = oldnode_under
		end

		local newnode = {name = nodename, param1 = 0, param2 = 0}

		-- Calculate direction
		local placer_pos = placer and placer:get_pos()
		if placer_pos then
			local dir = vector.subtract(above, placer_pos)
			newnode.param2 = minetest.dir_to_facedir(dir)
			log("info", "facedir: " .. newnode.param2)
		end

		-- pos for switcher
		local switcher_dir = get_dir_to_switcher(newnode)
		local switcher_pos = vector.add(place_to, switcher_dir)

		local switcher_name = "mesecons_transistors:switcher_off"
		local switcher_node = {name = switcher_name, param1 = 0, param2 = newnode.param2}
		local switcher_pointed_thing = {type = "node", above = vector.add(above, switcher_dir),
				under = vector.add(under, switcher_dir)}

		-- check if switcher pos is loaded and buildable to
		local switcher_oldnode = minetest.get_node_or_nil(switcher_pos)
		if not oldnode_under or not oldnode_above then
			log("info", playername .. " tried to place node in unloaded position " ..
					minetest.pos_to_string(switcher_pos))
			return itemstack
		end
		local switcher_oldnode_def = minetest.registered_nodes[switcher_oldnode.name]
		switcher_oldnode_def = switcher_oldnode_def or minetest.nodedef_default
		if not switcher_oldnode_def.buildable_to then
			log("info", playername .. " tried to place node in invalid position " ..
					minetest.pos_to_string(switcher_pos) .. ", replacing " ..
					switcher_oldnode.name)
			return itemstack
		end

		-- check protection
		if minetest.is_protected(place_to, playername) then
			log("action", playername .. " tried to place " .. nodename ..
					" at protected position " .. minetest.pos_to_string(place_to))
			minetest.record_protection_violation(place_to, playername)
			return itemstack
		end
		if minetest.is_protected(switcher_pos, playername) then
			log("action", playername .. " tried to place " .. switcher_name ..
					" at protected position " .. minetest.pos_to_string(switcher_pos))
			minetest.record_protection_violation(switcher_pos, playername)
			return itemstack
		end

		log("action", playername .. " places node " .. nodename .. " at " ..
				minetest.pos_to_string(place_to))

		-- Add nodes and update
		minetest.set_node(place_to, newnode)
		minetest.set_node(switcher_pos, switcher_node)

		-- Play sound if it was done by a player
		if playername ~= "" then
			local sounds = default.node_sound_stone_defaults()
			minetest.sound_play(sounds.place, {
				pos = place_to,
				exclude_player = playername,
			}, true)
		end

		local take_item = true

		-- Run script hook
		for _, callback in ipairs(core.registered_on_placenodes) do
			-- Deepcopy pos, node and pointed_thing because callback can modify them
			local place_to_copy = vector.new(place_to)
			local newnode_copy = {name = newnode.name, param1 = newnode.param1, param2 = newnode.param2}
			local oldnode_copy = {name = oldnode.name, param1 = oldnode.param1, param2 = oldnode.param2}
			local pointed_thing_copy = {type = "node", above = vector.new(above), under = vector.new(under)}
			if callback(place_to_copy, newnode_copy, placer, oldnode_copy, itemstack, pointed_thing_copy) then
				take_item = false
			end
		end
		for _, callback in ipairs(core.registered_on_placenodes) do
			-- Deepcopy pos, node and pointed_thing because callback can modify them
			local place_to_copy = vector.new(switcher_pos)
			local newnode_copy = {name = switcher_node.name, param1 = switcher_node.param1, param2 = switcher_node.param2}
			local oldnode_copy = {name = switcher_oldnode.name, param1 = switcher_oldnode.param1, param2 = switcher_oldnode.param2}
			local pointed_thing_copy = {type = "node", above = vector.new(switcher_pointed_thing.above),
					under = vector.new(switcher_pointed_thing.under)}
			if callback(place_to_copy, newnode_copy, placer, oldnode_copy, itemstack, pointed_thing_copy) then
				take_item = false
			end
		end

		if take_item then
			itemstack:take_item()
		end
		return itemstack
	end
end

local function transistor_after_dig_node(pos, oldnode, _, _)
	local switcher_pos = vector.add(pos, get_dir_to_switcher(oldnode))
	local old_switcher_node = mesecon.get_node_force(switcher_pos)
	if not old_switcher_node or old_switcher_node.param2 ~= oldnode.param2 or
			(old_switcher_node.name ~= "mesecons_transistors:switcher_off" and
			old_switcher_node.name ~= "mesecons_transistors:switcher_on") then
		return
	end
	minetest.remove_node(switcher_pos)
	mesecon.do_cooldown(switcher_pos)
	mesecon.on_dignode(pos, old_switcher_node)
end

local function switcher_on_dig(pos, node, digger)
	local conductor_pos = vector.add(pos, get_dir_to_switched(node))
	local conductor_node = mesecon.get_node_force(conductor_pos)
	if not conductor_node or conductor_node.param2 ~= node.param2 or
			not is_transistor_node[conductor_node.name] then
		return false
	end
	return minetest.node_dig(conductor_pos, conductor_node, digger)
end

local function generate_tiles(is_nc, is_closed, is_on)
	local tiles = {
		"jeija_microcontroller_bottom.png^mesecons_transistors_basepattern.png"..
			"^(mesecons_wire_off.png^[mask:mesecons_transistors_wire_mask.png)"..
			"^mesecons_transistors_no_open.png",
		"jeija_microcontroller_bottom.png",
		"jeija_microcontroller_bottom.png^jeija_gate_side_output_off.png",
		"jeija_microcontroller_bottom.png^jeija_gate_side_output_off.png",
		"jeija_microcontroller_bottom.png",
		"jeija_microcontroller_bottom.png^jeija_gate_side_output_off.png",
	}

	-- conductor wire
	local is_on_str = is_on and "on" or "off"
	tiles[1] = tiles[1] .. "^(mesecons_wire_" .. is_on_str ..
			".png^[mask:mesecons_transistors_wire_mask.png)"
	tiles[3] = tiles[3] .. "^jeija_gate_side_output_" .. is_on_str .. ".png"
	tiles[4] = tiles[4] .. "^jeija_gate_side_output_" .. is_on_str .. ".png"

	-- effector wire and closed/opened stuff
	tiles[1] = tiles[1] .. "^mesecons_transistors_" .. (is_nc and "nc" or "no")
			.. "_" .. (is_closed and "closed" or "open") .. ".png"
	tiles[6] = tiles[6] .. "^jeija_gate_side_output_" ..
			(is_nc == is_closed and "off" or "on") .. ".png"

	return tiles
end

mesecon.register_node("mesecons_transistors:switcher", {
	description = "You hacker you!",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	drawtype = "nodebox",
	node_box = node_box,
	sounds = default.node_sound_stone_defaults(),
	groups = {dig_immediate = 2, not_in_creative_inventory = 1, overheat = 1},
	drop = "",
	on_dig = switcher_on_dig,
	on_rotate = false,
}, {
	tiles = {
		"jeija_microcontroller_bottom.png"..
			"^(mesecons_wire_off.png^[mask:mesecons_transistors_switcher_mask.png)",
		"jeija_microcontroller_bottom.png",
		"jeija_microcontroller_bottom.png",
		"jeija_microcontroller_bottom.png",
		"jeija_microcontroller_bottom.png^jeija_gate_side_output_off.png",
		"jeija_microcontroller_bottom.png",
	},
	mesecons = {effector = {
		rules = get_switcher_inputrules,
		action_on = switcher_on,
	}},
}, {
	tiles = {
		"jeija_microcontroller_bottom.png"..
			"^(mesecons_wire_on.png^[mask:mesecons_transistors_switcher_mask.png)",
		"jeija_microcontroller_bottom.png",
		"jeija_microcontroller_bottom.png",
		"jeija_microcontroller_bottom.png",
		"jeija_microcontroller_bottom.png^jeija_gate_side_output_on.png",
		"jeija_microcontroller_bottom.png",
	},
	mesecons = {effector = {
		rules = get_switcher_inputrules,
		action_off = switcher_off,
	}}
})

minetest.register_node("mesecons_transistors:normally_open_contact_open", {
	description = "N/O contact",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	drawtype = "nodebox",
	node_box = node_box,
	node_placement_prediction = "",
	sounds = default.node_sound_stone_defaults(),
	groups = {dig_immediate = 2},
	tiles = generate_tiles(false, false, false),
	mesecons = {receptor = { -- pseudo-receptor to keep wires connected
		state = mesecon.state.off,
		rules = get_conductorrules,
	}},
	on_place = get_on_place_callback(false),
	after_dig_node = transistor_after_dig_node,
	on_rotate = false,
	on_blast = mesecon.on_blastnode,
})

mesecon.register_node("mesecons_transistors:normally_open_contact_closed", {
	description = "N/O contact (You hacker you!)",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	drawtype = "nodebox",
	drop = "mesecons_transistors:normally_open_contact_open",
	node_box = node_box,
	sounds = default.node_sound_stone_defaults(),
	groups = {dig_immediate = 2, not_in_creative_inventory = 1},
	after_dig_node = transistor_after_dig_node,
	on_rotate = false,
}, {
	tiles = generate_tiles(false, true, false),
	mesecons = {conductor = {
		state = mesecon.state.off,
		onstate = "mesecons_transistors:normally_open_contact_closed_on",
		rules = get_conductorrules,
	}},
}, {
	tiles = generate_tiles(false, true, true),
	mesecons = {conductor = {
		state = mesecon.state.on,
		offstate = "mesecons_transistors:normally_open_contact_closed_off",
		rules = get_conductorrules,
	}},
})

minetest.register_node("mesecons_transistors:normally_closed_contact_open", {
	description = "N/C contact (You hacker you!)",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	drawtype = "nodebox",
	drop = "mesecons_transistors:normally_closed_contact_closed_off",
	node_box = node_box,
	sounds = default.node_sound_stone_defaults(),
	groups = {dig_immediate = 2, not_in_creative_inventory = 1},
	tiles = generate_tiles(true, false, false),
	mesecons = {receptor = { -- pseudo-receptor to keep wires connected
		state = mesecon.state.off,
		rules = get_conductorrules,
	}},
	after_dig_node = transistor_after_dig_node,
	on_rotate = false,
	on_blast = mesecon.on_blastnode,
})

mesecon.register_node("mesecons_transistors:normally_closed_contact_closed", {
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	drawtype = "nodebox",
	drop = "mesecons_transistors:normally_closed_contact_closed_off",
	node_box = node_box,
	sounds = default.node_sound_stone_defaults(),
	after_dig_node = transistor_after_dig_node,
	on_rotate = false,
}, {
	description = "N/C contact",
	node_placement_prediction = "",
	groups = {dig_immediate = 2},
	tiles = generate_tiles(true, true, false),
	mesecons = {conductor = {
		state = mesecon.state.off,
		onstate = "mesecons_transistors:normally_closed_contact_closed_on",
		rules = get_conductorrules,
	}},
	on_place = get_on_place_callback(true),
}, {
	description = "N/C contact (You hacker you!)",
	groups = {dig_immediate = 2, not_in_creative_inventory = 1},
	tiles = generate_tiles(true, true, true),
	mesecons = {conductor = {
		state = mesecon.state.on,
		offstate = "mesecons_transistors:normally_closed_contact_closed_off",
		rules = get_conductorrules,
	}},
})

mesecon.register_mvps_stopper("mesecons_transistors:switcher_on")
mesecon.register_mvps_stopper("mesecons_transistors:switcher_off")
mesecon.register_mvps_stopper("mesecons_transistors:normally_open_contact_open")
mesecon.register_mvps_stopper("mesecons_transistors:normally_open_contact_closed_off")
mesecon.register_mvps_stopper("mesecons_transistors:normally_open_contact_closed_on")
mesecon.register_mvps_stopper("mesecons_transistors:normally_closed_contact_open")
mesecon.register_mvps_stopper("mesecons_transistors:normally_closed_contact_closed_off")
mesecon.register_mvps_stopper("mesecons_transistors:normally_closed_contact_closed_on")
