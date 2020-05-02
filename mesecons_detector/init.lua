local S = minetest.get_translator("mesecons_detector")
local F = minetest.formspec_escape

local GET_COMMAND = "GET"

-- Object detector
-- Detects players in a certain radius
-- The radius can be specified in mesecons/settings.lua

local function object_detector_make_formspec(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", "size[9,2.5]" ..
		"field[0.3,  0;9,2;scanname;"..F(S("Name of player to scan for (empty for any):"))..";${scanname}]"..
		"field[0.3,1.5;4,2;digiline_channel;"..F(S("Digiline Channel (optional):"))..";${digiline_channel}]"..
		"button_exit[7,0.75;2,3;;"..F(S("Save")).."]")
end

local function object_detector_on_receive_fields(pos, formname, fields, sender)
	if not fields.scanname or not fields.digiline_channel then return end

	if minetest.is_protected(pos, sender:get_player_name()) then return end

	local meta = minetest.get_meta(pos)
	meta:set_string("scanname", fields.scanname)
	meta:set_string("digiline_channel", fields.digiline_channel)
	object_detector_make_formspec(pos)
end

-- returns true if player was found, false if not
local function object_detector_scan(pos)
	local objs = minetest.get_objects_inside_radius(pos, mesecon.setting("detector_radius", 6))

	-- abort if no scan results were found
	if next(objs) == nil then return false end

	local scanname = minetest.get_meta(pos):get_string("scanname")
	local scan_for = {}
	for _, str in pairs(string.split(scanname:gsub(" ", ""), ",")) do
		scan_for[str] = true
	end

	local every_player = scanname == ""
	for _, obj in pairs(objs) do
		-- "" is returned if it is not a player; "" ~= nil; so only handle objects with foundname ~= ""
		local foundname = obj:get_player_name()
		if foundname ~= "" then
			if every_player or scan_for[foundname] then
				return true
			end
		end
	end

	return false
end

-- set player name when receiving a digiline signal on a specific channel
local object_detector_digiline = {
	effector = {
		action = function(pos, node, channel, msg)
			local meta = minetest.get_meta(pos)
			if channel == meta:get_string("digiline_channel") then
				meta:set_string("scanname", msg)
				object_detector_make_formspec(pos)
			end
		end,
	}
}

minetest.register_node("mesecons_detector:object_detector_off", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "jeija_object_detector_off.png", "jeija_object_detector_off.png", "jeija_object_detector_off.png", "jeija_object_detector_off.png"},
	paramtype = "light",
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3},
	description=S("Player Detector"),
	mesecons = {receptor = {
		state = mesecon.state.off,
		rules = mesecon.rules.pplate
	}},
	on_construct = object_detector_make_formspec,
	on_receive_fields = object_detector_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	digiline = object_detector_digiline,
	on_blast = mesecon.on_blastnode,
})

minetest.register_node("mesecons_detector:object_detector_on", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "jeija_object_detector_on.png", "jeija_object_detector_on.png", "jeija_object_detector_on.png", "jeija_object_detector_on.png"},
	paramtype = "light",
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3,not_in_creative_inventory=1},
	drop = 'mesecons_detector:object_detector_off',
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = mesecon.rules.pplate
	}},
	on_construct = object_detector_make_formspec,
	on_receive_fields = object_detector_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	digiline = object_detector_digiline,
	on_blast = mesecon.on_blastnode,
})

minetest.register_craft({
	output = 'mesecons_detector:object_detector_off',
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "mesecons_luacontroller:luacontroller0000", "default:steel_ingot"},
		{"default:steel_ingot", "group:mesecon_conductor_craftable", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = 'mesecons_detector:object_detector_off',
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "mesecons_microcontroller:microcontroller0000", "default:steel_ingot"},
		{"default:steel_ingot", "group:mesecon_conductor_craftable", "default:steel_ingot"},
	}
})

minetest.register_abm({
	nodenames = {"mesecons_detector:object_detector_off"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if not object_detector_scan(pos) then return end

		node.name = "mesecons_detector:object_detector_on"
		minetest.swap_node(pos, node)
		mesecon.receptor_on(pos, mesecon.rules.pplate)
	end,
})

minetest.register_abm({
	nodenames = {"mesecons_detector:object_detector_on"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if object_detector_scan(pos) then return end

		node.name = "mesecons_detector:object_detector_off"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos, mesecon.rules.pplate)
	end,
})

-- Node detector
-- Detects the node in front of it

local function node_detector_make_formspec(pos)
	local meta = minetest.get_meta(pos)
	if meta:get_string("distance") == ""  then meta:set_string("distance", "0") end
	meta:set_string("formspec", "size[9,2.5]" ..
		"field[0.3,  0;9,2;scanname;"..F(S("Name of node to scan for (empty for any):"))..";${scanname}]"..
		"field[0.3,1.5;2.5,2;distance;"..F(S("Distance (0-@1):", mesecon.setting("node_detector_distance_max", 10)))..";${distance}]"..
		"field[3,1.5;4,2;digiline_channel;"..F(S("Digiline Channel (optional):"))..";${digiline_channel}]"..
		"button_exit[7,0.75;2,3;;"..F(S("Save")).."]")
end

local function node_detector_on_receive_fields(pos, fieldname, fields, sender)
	if not fields.scanname or not fields.digiline_channel then return end

	if minetest.is_protected(pos, sender:get_player_name()) then return end

	local meta = minetest.get_meta(pos)
	meta:set_string("scanname", fields.scanname)
	meta:set_string("distance", fields.distance or "0")
	meta:set_string("digiline_channel", fields.digiline_channel)
	node_detector_make_formspec(pos)
end

-- returns true if node was found, false if not
local function node_detector_scan(pos)
	local node = minetest.get_node_or_nil(pos)
	if not node then return end

	local meta = minetest.get_meta(pos)

	local distance = meta:get_int("distance")
	local distance_max = mesecon.setting("node_detector_distance_max", 10)
	if distance < 0 then distance = 0 end
	if distance > distance_max then distance = distance_max end

	local frontname = minetest.get_node(
		vector.subtract(pos, vector.multiply(minetest.facedir_to_dir(node.param2), distance + 1))
	).name
	local scanname = meta:get_string("scanname")

	return (frontname == scanname) or
		(frontname ~= "air" and frontname ~= "ignore" and scanname == "")
end

local function node_detector_send_node_name(pos, node, channel, meta)
	local distance = meta:get_int("distance")
	local distance_max = mesecon.setting("node_detector_distance_max", 10)
	if distance < 0 then distance = 0 end
	if distance > distance_max then distance = distance_max end
	local nodename = minetest.get_node(
		vector.subtract(pos, vector.multiply(minetest.facedir_to_dir(node.param2), distance + 1))
	).name

	digiline:receptor_send(pos, digiline.rules.default, channel, nodename)
end

-- set player name when receiving a digiline signal on a specific channel
local node_detector_digiline = {
	effector = {
		action = function(pos, node, channel, msg)
			local meta = minetest.get_meta(pos)

			if channel ~= meta:get_string("digiline_channel") then return end

			if type(msg) == "table" then
				if msg.distance or msg.scanname then
					if msg.distance then
						meta:set_string("distance", msg.distance)
					end
					if msg.scanname then
						meta:set_string("scanname", msg.scanname)
					end
					node_detector_make_formspec(pos)
				end
				if msg.command == "get" then
					node_detector_send_node_name(pos, node, channel, meta)
				elseif msg.command == "scan" then
					local result = node_detector_scan(pos)
					digiline:receptor_send(pos, digiline.rules.default, channel, result)
				end
			else
				if msg == GET_COMMAND then
					node_detector_send_node_name(pos, node, channel, meta)
				else
					meta:set_string("scanname", msg)
					node_detector_make_formspec(pos)
				end
			end
		end,
	},
	receptor = {}
}

local function after_place_node_detector(pos, placer)
	local placer_pos = placer:getpos()
	if not placer_pos then
		return
	end

	--correct for the player's height
	if placer:is_player() then
		placer_pos.y = placer_pos.y + 1.625
	end

	--correct for 6d facedir
	local node = minetest.get_node(pos)
	node.param2 = minetest.dir_to_facedir(vector.subtract(pos, placer_pos), true)
	minetest.set_node(pos, node)
end

minetest.register_node("mesecons_detector:node_detector_off", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "jeija_node_detector_off.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3},
	description=S("Node Detector"),
	mesecons = {receptor = {
		state = mesecon.state.off
	}},
	on_construct = node_detector_make_formspec,
	on_receive_fields = node_detector_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	digiline = node_detector_digiline,
	on_blast = mesecon.on_blastnode,
})

minetest.register_node("mesecons_detector:node_detector_on", {
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "default_steel_block.png", "jeija_node_detector_on.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3,not_in_creative_inventory=1},
	drop = 'mesecons_detector:node_detector_off',
	mesecons = {receptor = {
		state = mesecon.state.on
	}},
	on_construct = node_detector_make_formspec,
	on_receive_fields = node_detector_on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	digiline = node_detector_digiline,
	on_blast = mesecon.on_blastnode,
})

minetest.register_craft({
	output = 'mesecons_detector:node_detector_off',
	recipe = {
		{"default:steel_ingot", "group:mesecon_conductor_craftable", "default:steel_ingot"},
		{"default:steel_ingot", "mesecons_luacontroller:luacontroller0000", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = 'mesecons_detector:node_detector_off',
	recipe = {
		{"default:steel_ingot", "group:mesecon_conductor_craftable", "default:steel_ingot"},
		{"default:steel_ingot", "mesecons_microcontroller:microcontroller0000", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})

minetest.register_abm({
	nodenames = {"mesecons_detector:node_detector_off"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if not node_detector_scan(pos) then return end

		node.name = "mesecons_detector:node_detector_on"
		minetest.swap_node(pos, node)
		mesecon.receptor_on(pos)
	end,
})

minetest.register_abm({
	nodenames = {"mesecons_detector:node_detector_on"},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		if node_detector_scan(pos) then return end

		node.name = "mesecons_detector:node_detector_off"
		minetest.swap_node(pos, node)
		mesecon.receptor_off(pos)
	end,
})
