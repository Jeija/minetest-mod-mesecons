-- Dig and place services

mesecon.on_placenode = function(pos, node)
	mesecon.execute_autoconnect_hooks_now(pos, node)

	-- Receptors: Send on signal when active
	if mesecon.is_receptor_on(node.name) then
		mesecon.receptor_on(pos, mesecon.receptor_get_rules(node))
	end

	-- Conductors: Send turnon signal when powered or replace by respective offstate conductor
	-- if placed conductor is an onstate one
	if mesecon.is_conductor(node.name) then
		local sources = mesecon.is_powered(pos)
		if sources then
			-- also call receptor_on if itself is powered already, so that neighboring
			-- conductors will be activated (when pushing an on-conductor with a piston)
			for _, s in ipairs(sources) do
				local rule = vector.subtract(s, pos)
				mesecon.turnon(pos, rule)
			end
			--mesecon.receptor_on (pos, mesecon.conductor_get_rules(node))
		elseif mesecon.is_conductor_on(node) then
			node.name = mesecon.get_conductor_off(node)
			minetest.swap_node(pos, node)
		end
	end

	-- Effectors: Send changesignal and activate or deactivate
	if mesecon.is_effector(node.name) then
		local powered_rules = {}
		local unpowered_rules = {}

		-- for each input rule, check if powered
		for _, r in ipairs(mesecon.effector_get_rules(node)) do
			local powered = mesecon.is_powered(pos, r)
			if powered then table.insert(powered_rules, r)
			else table.insert(unpowered_rules, r) end

			local state = powered and mesecon.state.on or mesecon.state.off
			mesecon.changesignal(pos, node, r, state, 1)
		end

		if (#powered_rules > 0) then
			for _, r in ipairs(powered_rules) do
				mesecon.activate(pos, node, r, 1)
			end
		else
			for _, r in ipairs(unpowered_rules) do
				mesecon.deactivate(pos, node, r, 1)
			end
		end
	end
end

mesecon.on_dignode = function(pos, node)
	if mesecon.is_conductor_on(node) then
		mesecon.receptor_off(pos, mesecon.conductor_get_rules(node))
	elseif mesecon.is_receptor_on(node.name) then
		mesecon.receptor_off(pos, mesecon.receptor_get_rules(node))
	end

	mesecon.execute_autoconnect_hooks_queue(pos, node)
end

function mesecon.on_blastnode(pos, intensity)
	local node = minetest.get_node(pos)
	minetest.remove_node(pos)
	mesecon.on_dignode(pos, node)
	return minetest.get_node_drops(node.name, "")
end

minetest.register_on_placenode(mesecon.on_placenode)
minetest.register_on_dignode(mesecon.on_dignode)

-- Overheating service for fast circuits
local OVERHEAT_MAX = mesecon.setting("overheat_max", 20)
local COOLDOWN_TIME = mesecon.setting("cooldown_time", 2.0)
local COOLDOWN_STEP = mesecon.setting("cooldown_granularity", 0.5)
local COOLDOWN_MULTIPLIER = OVERHEAT_MAX / COOLDOWN_TIME
local cooldown_timer = 0.0
local object_heat = {}

-- returns true if heat is too high
function mesecon.do_overheat(pos)
	local id = minetest.hash_node_position(pos)
	local heat = (object_heat[id] or 0) + 1
	object_heat[id] = heat
	if heat >= OVERHEAT_MAX then
		minetest.log("action", "Node overheats at " .. minetest.pos_to_string(pos))
		object_heat[id] = nil
		return true
	end
	return false
end

function mesecon.do_cooldown(pos)
	local id = minetest.hash_node_position(pos)
	object_heat[id] = nil
end

function mesecon.get_heat(pos)
	local id = minetest.hash_node_position(pos)
	return object_heat[id] or 0
end

function mesecon.move_hot_nodes(moved_nodes)
	local new_heat = {}
	for _, n in ipairs(moved_nodes) do
		local old_id = minetest.hash_node_position(n.oldpos)
		local new_id = minetest.hash_node_position(n.pos)
		new_heat[new_id] = object_heat[old_id]
		object_heat[old_id] = nil
	end
	for id, heat in pairs(new_heat) do
		object_heat[id] = heat
	end
end

local function global_cooldown(dtime)
	cooldown_timer = cooldown_timer + dtime
	if cooldown_timer < COOLDOWN_STEP then
		return -- don't overload the CPU
	end
	local cooldown = COOLDOWN_MULTIPLIER * cooldown_timer
	cooldown_timer = 0
	for id, heat in pairs(object_heat) do
		heat = heat - cooldown
		if heat <= 0 then
			object_heat[id] = nil -- free some RAM
		else
			object_heat[id] = heat
		end
	end
end
minetest.register_globalstep(global_cooldown)
