--register stoppers for movestones/pistons

mesecon.mvps_stoppers = {}
mesecon.on_mvps_move = {}
mesecon.mvps_unmov = {}

--- Objects (entities) that cannot be moved
function mesecon.register_mvps_unmov(objectname)
	mesecon.mvps_unmov[objectname] = true;
end

function mesecon.is_mvps_unmov(objectname)
	return mesecon.mvps_unmov[objectname]
end

-- Nodes that cannot be pushed / pulled by movestones, pistons
function mesecon.is_mvps_stopper(node, pushdir, stack, stackid)
	-- unknown nodes are always stoppers
	if not minetest.registered_nodes[node.name] then
		return true
	end

	local get_stopper = mesecon.mvps_stoppers[node.name]
	if type (get_stopper) == "function" then
		get_stopper = get_stopper(node, pushdir, stack, stackid)
	end

	return get_stopper
end

function mesecon.register_mvps_stopper(nodename, get_stopper)
	if minetest.registered_nodes[nodename] and minetest.registered_nodes[nodename].buildable_to then
		minetest.log("warning", ("Registering a buildable-to node \"%s\" as a mesecon stopper, this is not supported"):format(nodename))
	end
	if get_stopper == nil then
			get_stopper = true
	end
	mesecon.mvps_stoppers[nodename] = get_stopper
end

-- Functions to be called on mvps movement
function mesecon.register_on_mvps_move(callback)
	mesecon.on_mvps_move[#mesecon.on_mvps_move+1] = callback
end

local function on_mvps_move(moved_nodes)
	for _, callback in ipairs(mesecon.on_mvps_move) do
		callback(moved_nodes)
	end
end

function mesecon.mvps_process_stack(stack)
	-- update mesecons for placed nodes ( has to be done after all nodes have been added )
	for _, n in ipairs(stack) do
		mesecon.on_placenode(n.pos, minetest.get_node(n.pos))
	end
end

-- tests if the node can be pushed into, e.g. air, water, grass
local function node_replaceable(name)
	if minetest.registered_nodes[name] then
		return minetest.registered_nodes[name].buildable_to or false
	end

	return false
end

function mesecon.mvps_get_stack(pos, dir, maximum, all_pull_sticky)
	-- determine the number of nodes to be pushed
	local nodes = {}
	local frontiers = {pos}

	while #frontiers > 0 do
		local np = frontiers[1]
		local nn = minetest.get_node(np)

		-- Never push into unloaded blocks. Don’t try to pull from them, either.
		-- TODO: load blocks instead, as with wires.
		if nn.name == "ignore" then return nil end

		if not node_replaceable(nn.name) then
			table.insert(nodes, {node = nn, pos = np})
			if #nodes > maximum then return nil end

			-- add connected nodes to frontiers, connected is a vector list
			-- the vectors must be absolute positions
			local connected = {}
			if minetest.registered_nodes[nn.name]
			and minetest.registered_nodes[nn.name].mvps_sticky then
				connected = minetest.registered_nodes[nn.name].mvps_sticky(np, nn)
			end

			table.insert(connected, vector.add(np, dir))

			-- If adjacent node is sticky block and connects add that
			-- position to the connected table
			for _, r in ipairs(mesecon.rules.alldirs) do
				local adjpos = vector.add(np, r)
				local adjnode = minetest.get_node(adjpos)
				if minetest.registered_nodes[adjnode.name]
				and minetest.registered_nodes[adjnode.name].mvps_sticky then
					local sticksto = minetest.registered_nodes[adjnode.name]
						.mvps_sticky(adjpos, adjnode)

					-- connects to this position?
					for _, link in ipairs(sticksto) do
						if vector.equals(link, np) then
							table.insert(connected, adjpos)
						end
					end
				end
			end

			if all_pull_sticky then
				table.insert(connected, vector.subtract(np, dir))
			end

			-- Make sure there are no duplicates in frontiers / nodes before
			-- adding nodes in "connected" to frontiers
			for _, cp in ipairs(connected) do
				local duplicate = false
				for _, rp in ipairs(nodes) do
					if vector.equals(cp, rp.pos) then
						duplicate = true
					end
				end
				for _, fp in ipairs(frontiers) do
					if vector.equals(cp, fp) then
						duplicate = true
					end
				end
				if not duplicate then
					table.insert(frontiers, cp)
				end
			end
		end
		table.remove(frontiers, 1)
	end

	return nodes
end

function mesecon.mvps_set_owner(pos, placer)
	local meta = minetest.get_meta(pos)
	local owner = placer and placer.get_player_name and placer:get_player_name()
	if owner and owner ~= "" then
		meta:set_string("owner", owner)
	else
		meta:set_string("owner", "$unknown") -- to distinguish from older pistons
	end
end

function mesecon.mvps_claim(pos, player_name)
	if not player_name or player_name == "" then return end
	local meta = minetest.get_meta(pos)
	if meta:get_string("infotext") == "" then return end
	if meta:get_string("owner") == player_name then return end -- already owned
	if minetest.is_protected(pos, player_name) then
		minetest.chat_send_player(player_name, "Can't reclaim: protected")
		return
	end
	meta:set_string("owner", player_name)
	meta:set_string("infotext", "")
	return true
end

local function add_pos(positions, pos)
	local hash = minetest.hash_node_position(pos)
	positions[hash] = pos
end

local function are_protected(positions, player_name)
	local mode = mesecon.setting("mvps_protection_mode", "compat")
	if mode == "ignore" then
		return false
	end
	local name = player_name
	if player_name == "" or not player_name then -- legacy MVPS
		if mode == "normal" then
			name = "$unknown" -- sentinel, for checking for *any* protection
		elseif mode == "compat" then
			return false
		elseif mode == "restrict" then
			return true
		else
			error("Invalid protection mode")
		end
	end
	local is_protected = minetest.is_protected
	for _, pos in pairs(positions) do
		if is_protected(pos, name) then
			return true
		end
	end
	return false
end

function mesecon.mvps_push(pos, dir, maximum, player_name)
	return mesecon.mvps_push_or_pull(pos, dir, dir, maximum, false, player_name)
end

function mesecon.mvps_pull_all(pos, dir, maximum, player_name)
	return mesecon.mvps_push_or_pull(pos, vector.multiply(dir, -1), dir, maximum, true, player_name)
end

function mesecon.mvps_pull_single(pos, dir, maximum, player_name)
	return mesecon.mvps_push_or_pull(pos, vector.multiply(dir, -1), dir, maximum, false, player_name)
end

-- pos: pos of mvps
-- stackdir: direction of building the stack
-- movedir: direction of actual movement
-- maximum: maximum nodes to be pushed
-- all_pull_sticky: All nodes are sticky in the direction that they are pulled from
-- player_name: Player responsible for the action.
--  - empty string means legacy MVPS, actual check depends on configuration
--  - "$unknown" is a sentinel for forcing the check
function mesecon.mvps_push_or_pull(pos, stackdir, movedir, maximum, all_pull_sticky, player_name)
	local nodes = mesecon.mvps_get_stack(pos, movedir, maximum, all_pull_sticky)

	if not nodes then return end

	local protection_check_set = {}
	if vector.equals(stackdir, movedir) then -- pushing
		add_pos(protection_check_set, pos)
	end
	-- determine if one of the nodes blocks the push / pull
	for id, n in ipairs(nodes) do
		if mesecon.is_mvps_stopper(n.node, movedir, nodes, id) then
			return
		end
		add_pos(protection_check_set, n.pos)
		add_pos(protection_check_set, vector.add(n.pos, movedir))
	end
	if are_protected(protection_check_set, player_name) then
		return false, "protected"
	end

	-- remove all nodes
	for _, n in ipairs(nodes) do
		n.meta = minetest.get_meta(n.pos):to_table()
		local node_timer = minetest.get_node_timer(n.pos)
		if node_timer:is_started() then
			n.node_timer = {node_timer:get_timeout(), node_timer:get_elapsed()}
		end
		minetest.remove_node(n.pos)
	end

	-- update mesecons for removed nodes ( has to be done after all nodes have been removed )
	for _, n in ipairs(nodes) do
		mesecon.on_dignode(n.pos, n.node)
	end

	-- add nodes
	for _, n in ipairs(nodes) do
		local np = vector.add(n.pos, movedir)

		minetest.set_node(np, n.node)
		minetest.get_meta(np):from_table(n.meta)
		if n.node_timer then
			minetest.get_node_timer(np):set(unpack(n.node_timer))
		end
	end

	local moved_nodes = {}
	local oldstack = mesecon.tablecopy(nodes)
	for i in ipairs(nodes) do
		moved_nodes[i] = {}
		moved_nodes[i].oldpos = nodes[i].pos
		nodes[i].pos = vector.add(nodes[i].pos, movedir)
		moved_nodes[i].pos = nodes[i].pos
		moved_nodes[i].node = nodes[i].node
		moved_nodes[i].meta = nodes[i].meta
		moved_nodes[i].node_timer = nodes[i].node_timer
	end

	on_mvps_move(moved_nodes)

	return true, nodes, oldstack
end

function mesecon.mvps_move_objects(pos, dir, nodestack, movefactor)
	local objects_to_move = {}
	local dir_k
	local dir_l
	for k, v in pairs(dir) do
		if v ~= 0 then
			dir_k = k
			dir_l = v
			break
		end
	end
	movefactor = movefactor or 1
	dir = vector.multiply(dir, movefactor)
	for id, obj in pairs(minetest.get_objects_inside_radius(pos, #nodestack + 1)) do
		local obj_pos = obj:get_pos()
		local cbox = obj:get_properties().collisionbox
		local min_pos = vector.add(obj_pos, vector.new(cbox[1], cbox[2], cbox[3]))
		local max_pos = vector.add(obj_pos, vector.new(cbox[4], cbox[5], cbox[6]))
		local ok = true
		for k, v in pairs(pos) do
			local edge1, edge2
			if k ~= dir_k then
				edge1 = v - 0.51 -- More than 0.5 to move objects near to the stack.
				edge2 = v + 0.51
			else
				edge1 = v - 0.5 * dir_l
				edge2 = v + (#nodestack + 0.5 * movefactor) * dir_l
				-- Make sure, edge1 is bigger than edge2:
				if edge1 > edge2 then
					edge1, edge2 = edge2, edge1
				end
			end
			if min_pos[k] > edge2 or max_pos[k] < edge1 then
				ok = false
				break
			end
		end
		if ok then
			local ent = obj:get_luaentity()
			if obj:is_player() or (ent and not mesecon.is_mvps_unmov(ent.name)) then
				local np = vector.add(obj_pos, dir)
				-- Move only if destination is not solid or object is inside stack:
				local nn = minetest.get_node(np)
				local node_def = minetest.registered_nodes[nn.name]
				local obj_offset = dir_l * (obj_pos[dir_k] - pos[dir_k])
				if (node_def and not node_def.walkable) or
						(obj_offset >= 0 and
						obj_offset <= #nodestack - 0.5) then
					obj:move_to(np)
				end
			end
		end
	end
end

mesecon.register_mvps_stopper("doors:door_steel_b_1")
mesecon.register_mvps_stopper("doors:door_steel_t_1")
mesecon.register_mvps_stopper("doors:door_steel_b_2")
mesecon.register_mvps_stopper("doors:door_steel_t_2")
mesecon.register_mvps_stopper("default:chest_locked")
mesecon.register_on_mvps_move(mesecon.move_hot_nodes)
mesecon.register_on_mvps_move(function(moved_nodes)
	for i = 1, #moved_nodes do
		local moved_node = moved_nodes[i]
		mesecon.on_placenode(moved_node.pos, moved_node.node)
		minetest.after(0, function()
			minetest.check_for_falling(moved_node.oldpos)
			minetest.check_for_falling(moved_node.pos)
		end)
		local node_def = minetest.registered_nodes[moved_node.node.name]
		if node_def and node_def.mesecon and node_def.mesecon.on_mvps_move then
			node_def.mesecon.on_mvps_move(moved_node.pos, moved_node.node,
					moved_node.oldpos, moved_node.meta)
		end
	end
end)
