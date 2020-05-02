local S = minetest.get_translator("mesecons_wires")

-- naming scheme: wire:(xp)(zp)(xm)(zm)(xpyp)(zpyp)(xmyp)(zmyp)_on/off
-- where x= x direction, z= z direction, y= y direction, p = +1, m = -1, e.g. xpym = {x=1, y=-1, z=0}
-- The (xp)/(zpyp)/.. statements shall be replaced by either 0 or 1
-- Where 0 means the wire has no visual connection to that direction and
-- 1 means that the wire visually connects to that other node.

-- #######################
-- ## Update wire looks ##
-- #######################

-- self_pos = pos of any mesecon node, from_pos = pos of conductor to getconnect for
local wire_getconnect = function (from_pos, self_pos)
	local node = minetest.get_node(self_pos)
	if minetest.registered_nodes[node.name]
	and minetest.registered_nodes[node.name].mesecons then
		-- rules of node to possibly connect to
		local rules = {}
		if (minetest.registered_nodes[node.name].mesecon_wire) then
			rules = mesecon.rules.default
		else
			rules = mesecon.get_any_rules(node)
		end

		for _, r in ipairs(mesecon.flattenrules(rules)) do
			if (vector.equals(vector.add(self_pos, r), from_pos)) then
				return true
			end
		end
	end
	return false
end

-- Update this node
local wire_updateconnect = function (pos)
	local connections = {}

	for _, r in ipairs(mesecon.rules.default) do
		if wire_getconnect(pos, vector.add(pos, r)) then
			table.insert(connections, r)
		end
	end

	local nid = {}
	for _, vec in ipairs(connections) do
		-- flat component
		if vec.x ==  1 then nid[0] = "1" end
		if vec.z ==  1 then nid[1] = "1" end
		if vec.x == -1 then nid[2] = "1" end
		if vec.z == -1 then nid[3] = "1"  end

		-- slopy component
		if vec.y == 1 then
			if vec.x ==  1 then nid[4] = "1" end
			if vec.z ==  1 then nid[5] = "1" end
			if vec.x == -1 then nid[6] = "1" end
			if vec.z == -1 then nid[7] = "1" end
		end
	end

	local nodeid = 	  (nid[0] or "0")..(nid[1] or "0")..(nid[2] or "0")..(nid[3] or "0")
			..(nid[4] or "0")..(nid[5] or "0")..(nid[6] or "0")..(nid[7] or "0")

	local state_suffix = string.find(minetest.get_node(pos).name, "_off") and "_off" or "_on"
	minetest.set_node(pos, {name = "mesecons:wire_"..nodeid..state_suffix})
end

local update_on_place_dig = function (pos, node)
	-- Update placed node (get_node again as it may have been dug)
	local nn = minetest.get_node(pos)
	if (minetest.registered_nodes[nn.name])
	and (minetest.registered_nodes[nn.name].mesecon_wire) then
		wire_updateconnect(pos)
	end

	-- Update nodes around it
	local rules = {}
	if minetest.registered_nodes[node.name]
	and minetest.registered_nodes[node.name].mesecon_wire then
		rules = mesecon.rules.default
	else
		rules = mesecon.get_any_rules(node)
	end
	if (not rules) then return end

	for _, r in ipairs(mesecon.flattenrules(rules)) do
		local np = vector.add(pos, r)
		if minetest.registered_nodes[minetest.get_node(np).name]
		and minetest.registered_nodes[minetest.get_node(np).name].mesecon_wire then
			wire_updateconnect(np)
		end
	end
end

mesecon.register_autoconnect_hook("wire", update_on_place_dig)

-- ############################
-- ## Wire node registration ##
-- ############################
-- Nodeboxes:
local box_center = {-1/16, -.5, -1/16, 1/16, -.5+1/16, 1/16}
local box_bump1 =  { -2/16, -8/16,  -2/16, 2/16, -13/32, 2/16 }

local nbox_nid =
{
	[0] = {1/16, -.5, -1/16, 8/16, -.5+1/16, 1/16}, -- x positive
	[1] = {-1/16, -.5, 1/16, 1/16, -.5+1/16, 8/16}, -- z positive
	[2] = {-8/16, -.5, -1/16, -1/16, -.5+1/16, 1/16}, -- x negative
	[3] = {-1/16, -.5, -8/16, 1/16, -.5+1/16, -1/16}, -- z negative

	[4] = {.5-1/16, -.5+1/16, -1/16, .5, .4999+1/16, 1/16}, -- x positive up
	[5] = {-1/16, -.5+1/16, .5-1/16, 1/16, .4999+1/16, .5}, -- z positive up
	[6] = {-.5, -.5+1/16, -1/16, -.5+1/16, .4999+1/16, 1/16}, -- x negative up
	[7] = {-1/16, -.5+1/16, -.5, 1/16, .4999+1/16, -.5+1/16}  -- z negative up
}

local tiles_off = { "mesecons_wire_off.png" }
local tiles_on = { "mesecons_wire_on.png" }

local selectionbox =
{
	type = "fixed",
	fixed = {-.5, -.5, -.5, .5, -.5+4/16, .5}
}

-- go to the next nodeid (ex.: 01000011 --> 01000100)
local nid_inc = function() end
nid_inc = function (nid)
	local i = 0
	while nid[i-1] ~= 1 do
		nid[i] = (nid[i] ~= 1) and 1 or 0
		i = i + 1
	end

	-- BUT: Skip impossible nodeids:
	if ((nid[0] == 0 and nid[4] == 1) or (nid[1] == 0 and nid[5] == 1)
	or (nid[2] == 0 and nid[6] == 1) or (nid[3] == 0 and nid[7] == 1)) then
		return nid_inc(nid)
	end

	return i <= 8
end

local function register_wires()
	local nid = {}
	while true do
		-- Create group specifiction and nodeid string (see note above for details)
		local nodeid = 	  (nid[0] or "0")..(nid[1] or "0")..(nid[2] or "0")..(nid[3] or "0")
				..(nid[4] or "0")..(nid[5] or "0")..(nid[6] or "0")..(nid[7] or "0")

		-- Calculate nodebox
		local nodebox = {type = "fixed", fixed={box_center}}
		for i=0,7 do
			if nid[i] == 1 then
				table.insert(nodebox.fixed, nbox_nid[i])
			end
		end

		-- Add bump to nodebox if curved
		if (nid[0] == 1 and nid[1] == 1) or (nid[1] == 1 and nid[2] == 1)
		or (nid[2] == 1 and nid[3] == 1) or (nid[3] == 1 and nid[0] == 1) then
			table.insert(nodebox.fixed, box_bump1)
		end

		-- If nothing to connect to, still make a nodebox of a straight wire
		if nodeid == "00000000" then
			nodebox.fixed = {-8/16, -.5, -1/16, 8/16, -.5+1/16, 1/16}
		end

		local rules = {}
		if (nid[0] == 1) then table.insert(rules, vector.new( 1,  0,  0)) end
		if (nid[1] == 1) then table.insert(rules, vector.new( 0,  0,  1)) end
		if (nid[2] == 1) then table.insert(rules, vector.new(-1,  0,  0)) end
		if (nid[3] == 1) then table.insert(rules, vector.new( 0,  0, -1)) end

		if (nid[0] == 1) then table.insert(rules, vector.new( 1, -1,  0)) end
		if (nid[1] == 1) then table.insert(rules, vector.new( 0, -1,  1)) end
		if (nid[2] == 1) then table.insert(rules, vector.new(-1, -1,  0)) end
		if (nid[3] == 1) then table.insert(rules, vector.new( 0, -1, -1)) end

		if (nid[4] == 1) then table.insert(rules, vector.new( 1,  1,  0)) end
		if (nid[5] == 1) then table.insert(rules, vector.new( 0,  1,  1)) end
		if (nid[6] == 1) then table.insert(rules, vector.new(-1,  1,  0)) end
		if (nid[7] == 1) then table.insert(rules, vector.new( 0,  1, -1)) end

		local meseconspec_off = { conductor = {
			rules = rules,
			state = mesecon.state.off,
			onstate = "mesecons:wire_"..nodeid.."_on"
		}}

		local meseconspec_on = { conductor = {
			rules = rules,
			state = mesecon.state.on,
			offstate = "mesecons:wire_"..nodeid.."_off"
		}}

		local groups_on = {dig_immediate = 3, mesecon_conductor_craftable = 1,
			not_in_creative_inventory = 1}
		local groups_off = {dig_immediate = 3, mesecon_conductor_craftable = 1}
		if nodeid ~= "00000000" then
			groups_off["not_in_creative_inventory"] = 1
		end

		mesecon.register_node(":mesecons:wire_"..nodeid, {
			description = S("Mesecon"),
			drawtype = "nodebox",
			inventory_image = "mesecons_wire_inv.png",
			wield_image = "mesecons_wire_inv.png",
			paramtype = "light",
			paramtype2 = "facedir",
			is_ground_content = false,
			sunlight_propagates = true,
			selection_box = selectionbox,
			node_box = nodebox,
			walkable = false,
			drop = "mesecons:wire_00000000_off",
			mesecon_wire = true,
			sounds = default.node_sound_defaults(),
			on_rotate = false,
		}, {tiles = tiles_off, mesecons = meseconspec_off, groups = groups_off},
		{tiles = tiles_on, mesecons = meseconspec_on, groups = groups_on})

		if (nid_inc(nid) == false) then return end
	end
end
register_wires()

-- ##############
-- ## Crafting ##
-- ##############
minetest.register_craft({
	type = "cooking",
	output = "mesecons:wire_00000000_off 2",
	recipe = "default:mese_crystal_fragment",
	cooktime = 3,
})

minetest.register_craft({
	type = "cooking",
	output = "mesecons:wire_00000000_off 18",
	recipe = "default:mese_crystal",
	cooktime = 15,
})

minetest.register_craft({
	type = "cooking",
	output = "mesecons:wire_00000000_off 162",
	recipe = "default:mese",
	cooktime = 30,
})
