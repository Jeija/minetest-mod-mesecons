local S = minetest.get_translator("mesecons_luacontroller")
local F = minetest.formspec_escape

--        ______
--       |
--       |
--       |        __       ___  _   __         _  _
-- |   | |       |  | |\ |  |  |_| |  | |  |  |_ |_|
-- |___| |______ |__| | \|  |  | \ |__| |_ |_ |_ |\
-- |
-- |
--

-- Reference
-- ports = get_real_port_states(pos): gets if inputs are powered from outside
-- newport = merge_port_states(state1, state2): just does result = state1 or state2 for every port
-- set_port(pos, rule, state): activates/deactivates the mesecons according to the port states
-- set_port_states(pos, ports): Applies new port states to a Luacontroller at pos
-- run_inner(pos, code, event): runs code on the controller at pos and event
-- reset_formspec(pos, code, errmsg): installs new code and prints error messages, without resetting LCID
-- reset_meta(pos, code, errmsg): performs a software-reset, installs new code and prints error message
-- run(pos, event): a wrapper for run_inner which gets code & handles errors via reset_meta
-- resetn(pos): performs a hardware reset, turns off all ports
--
-- The Sandbox
-- The whole code of the controller runs in a sandbox,
-- a very restricted environment.
-- Actually the only way to damage the server is to
-- use too much memory from the sandbox.
-- You can add more functions to the environment
-- (see where local env is defined)
-- Something nice to play is is appending minetest.env to it.

local BASENAME = "mesecons_luacontroller:luacontroller"

local rules = {
	a = {x = -1, y = 0, z =  0, name="A"},
	b = {x =  0, y = 0, z =  1, name="B"},
	c = {x =  1, y = 0, z =  0, name="C"},
	d = {x =  0, y = 0, z = -1, name="D"},
}


------------------
-- Action stuff --
------------------
-- These helpers are required to set the port states of the luacontroller

local function update_real_port_states(pos, rule_name, new_state)
	local meta = minetest.get_meta(pos)
	if rule_name == nil then
		meta:set_int("real_portstates", 1)
		return
	end
	local n = meta:get_int("real_portstates") - 1
	local L = {}
	for i = 1, 4 do
		L[i] = n % 2
		n = math.floor(n / 2)
	end
	--                   (0,-1) (-1,0)      (1,0) (0,1)
	local pos_to_side = {  4,     1,   nil,   3,    2 }
	if rule_name.x == nil then
		for _, rname in ipairs(rule_name) do
			local port = pos_to_side[rname.x + (2 * rname.z) + 3]
			L[port] = (newstate == "on") and 1 or 0
		end
	else
		local port = pos_to_side[rule_name.x + (2 * rule_name.z) + 3]
		L[port] = (new_state == "on") and 1 or 0
	end
	meta:set_int("real_portstates",
		1 +
		1 * L[1] +
		2 * L[2] +
		4 * L[3] +
		8 * L[4])
end


local port_names = {"a", "b", "c", "d"}

local function get_real_port_states(pos)
	-- Determine if ports are powered (by itself or from outside)
	local meta = minetest.get_meta(pos)
	local L = {}
	local n = meta:get_int("real_portstates") - 1
	for _, name in ipairs(port_names) do
		L[name] = ((n % 2) == 1)
		n = math.floor(n / 2)
	end
	return L
end


local function merge_port_states(ports, vports)
	return {
		a = ports.a or vports.a,
		b = ports.b or vports.b,
		c = ports.c or vports.c,
		d = ports.d or vports.d,
	}
end

local function generate_name(ports)
	local d = ports.d and 1 or 0
	local c = ports.c and 1 or 0
	local b = ports.b and 1 or 0
	local a = ports.a and 1 or 0
	return BASENAME..d..c..b..a
end


local function set_port(pos, rule, state)
	if state then
		mesecon.receptor_on(pos, {rule})
	else
		mesecon.receptor_off(pos, {rule})
	end
end


local function clean_port_states(ports)
	ports.a = ports.a and true or false
	ports.b = ports.b and true or false
	ports.c = ports.c and true or false
	ports.d = ports.d and true or false
end


local function set_port_states(pos, ports)
	local node = minetest.get_node(pos)
	local name = node.name
	clean_port_states(ports)
	local vports = minetest.registered_nodes[name].virtual_portstates
	local new_name = generate_name(ports)

	if name ~= new_name and vports then
		-- Problem:
		-- We need to place the new node first so that when turning
		-- off some port, it won't stay on because the rules indicate
		-- there is an onstate output port there.
		-- When turning the output off then, it will however cause feedback
		-- so that the luacontroller will receive an "off" event by turning
		-- its output off.
		-- Solution / Workaround:
		-- Remember which output was turned off and ignore next "off" event.
		local meta = minetest.get_meta(pos)
		local ign = minetest.deserialize(meta:get_string("ignore_offevents"), true) or {}
		if ports.a and not vports.a and not mesecon.is_powered(pos, rules.a) then ign.A = true end
		if ports.b and not vports.b and not mesecon.is_powered(pos, rules.b) then ign.B = true end
		if ports.c and not vports.c and not mesecon.is_powered(pos, rules.c) then ign.C = true end
		if ports.d and not vports.d and not mesecon.is_powered(pos, rules.d) then ign.D = true end
		meta:set_string("ignore_offevents", minetest.serialize(ign))

		minetest.swap_node(pos, {name = new_name, param2 = node.param2})

		if ports.a ~= vports.a then set_port(pos, rules.a, ports.a) end
		if ports.b ~= vports.b then set_port(pos, rules.b, ports.b) end
		if ports.c ~= vports.c then set_port(pos, rules.c, ports.c) end
		if ports.d ~= vports.d then set_port(pos, rules.d, ports.d) end
	end
end


-----------------
-- Overheating --
-----------------
local function burn_controller(pos)
	local node = minetest.get_node(pos)
	node.name = BASENAME.."_burnt"
	minetest.swap_node(pos, node)
	minetest.get_meta(pos):set_string("lc_memory", "");
	-- Wait for pending operations
	minetest.after(0.2, mesecon.receptor_off, pos, mesecon.rules.flat)
end

local function overheat(pos, meta)
	if mesecon.do_overheat(pos) then -- If too hot
		burn_controller(pos)
		return true
	end
end

------------------------
-- Ignored off events --
------------------------

local function ignore_event(event, meta)
	if event.type ~= "off" then return false end
	local ignore_offevents = minetest.deserialize(meta:get_string("ignore_offevents"), true) or {}
	if ignore_offevents[event.pin.name] then
		ignore_offevents[event.pin.name] = nil
		meta:set_string("ignore_offevents", minetest.serialize(ignore_offevents))
		return true
	end
end

-------------------------
-- Parsing and running --
-------------------------

local function safe_print(param)
	local string_meta = getmetatable("")
	local sandbox = string_meta.__index
	string_meta.__index = string -- Leave string sandbox temporarily
	print(dump(param))
	string_meta.__index = sandbox -- Restore string sandbox
end

local function safe_date()
	return(os.date("*t",os.time()))
end

-- string.rep(str, n) with a high value for n can be used to DoS
-- the server. Therefore, limit max. length of generated string.
local function safe_string_rep(str, n)
	if #str * n > mesecon.setting("luacontroller_string_rep_max", 64000) then
		debug.sethook() -- Clear hook
		error("string.rep: string length overflow", 2)
	end

	return string.rep(str, n)
end

-- string.find with a pattern can be used to DoS the server.
-- Therefore, limit string.find to patternless matching.
local function safe_string_find(...)
	if (select(4, ...)) ~= true then
		debug.sethook() -- Clear hook
		error("string.find: 'plain' (fourth parameter) must always be true in a Luacontroller")
	end

	return string.find(...)
end

local function remove_functions(x)
	local tp = type(x)
	if tp == "function" then
		return nil
	end

	-- Make sure to not serialize the same table multiple times, otherwise
	-- writing mem.test = mem in the Luacontroller will lead to infinite recursion
	local seen = {}

	local function rfuncs(x)
		if x == nil then return end
		if seen[x] then return end
		seen[x] = true
		if type(x) ~= "table" then return end

		for key, value in pairs(x) do
			if type(key) == "function" or type(value) == "function" then
				x[key] = nil
			else
				if type(key) == "table" then
					rfuncs(key)
				end
				if type(value) == "table" then
					rfuncs(value)
				end
			end
		end
	end

	rfuncs(x)

	return x
end

-- The setting affects API so is not intended to be changeable at runtime
local get_interrupt
if mesecon.setting("luacontroller_lightweight_interrupts", false) then
	-- use node timer
	get_interrupt = function(pos, itbl, send_warning)
		return (function(time, iid)
			if type(time) ~= "number" then error("Delay must be a number") end
			if iid ~= nil then send_warning(S("Interrupt IDs are disabled on this server")) end
			table.insert(itbl, function() minetest.get_node_timer(pos):start(time) end)
		end)
	end
else
	-- use global action queue
	-- itbl: Flat table of functions to run after sandbox cleanup, used to prevent various security hazards
	get_interrupt = function(pos, itbl, send_warning)
		-- iid = interrupt id
		local function interrupt(time, iid)
			-- NOTE: This runs within string metatable sandbox, so don't *rely* on anything of the form (""):y
			-- Hence the values get moved out. Should take less time than original, so totally compatible
			if type(time) ~= "number" then error("Delay must be a number") end
			table.insert(itbl, function ()
				-- Outside string metatable sandbox, can safely run this now
				local luac_id = minetest.get_meta(pos):get_int("luac_id")
				-- Check if IID is dodgy, so you can't use interrupts to store an infinite amount of data.
				-- Note that this is safe from alter-after-free because this code gets run after the sandbox has ended.
				-- This runs outside of the timer and *shouldn't* harm perf. unless dodgy data is being sent in the first place
				iid = remove_functions(iid)
				local msg_ser = minetest.serialize(iid)
				if #msg_ser <= mesecon.setting("luacontroller_interruptid_maxlen", 256) then
					mesecon.queue:add_action(pos, "lc_interrupt", {luac_id, iid}, time, iid, 1)
				else
					send_warning(S("An interrupt ID was too large!"))
				end
			end)
		end
		return interrupt
	end
end

-- Given a message object passed to digiline_send, clean it up into a form
-- which is safe to transmit over the network and compute its "cost" (a very
-- rough estimate of its memory usage).
--
-- The cleaning comprises the following:
-- 1. Functions (and userdata, though user scripts ought not to get hold of
--    those in the first place) are removed, because they break the model of
--    Digilines as a network that carries basic data, and they could exfiltrate
--    references to mutable objects from one Luacontroller to another, allowing
--    inappropriate high-bandwidth, no-wires communication.
-- 2. Tables are duplicated because, being mutable, they could otherwise be
--    modified after the send is complete in order to change what data arrives
--    at the recipient, perhaps in violation of the previous cleaning rule or
--    in violation of the message size limit.
--
-- The cost indication is only approximate; it’s not a perfect measurement of
-- the number of bytes of memory used by the message object.
--
-- Parameters:
-- msg -- the message to clean
-- back_references -- for internal use only; do not provide
--
-- Returns:
-- 1. The cleaned object.
-- 2. The approximate cost of the object.
local function clean_and_weigh_digiline_message(msg, back_references)
	local t = type(msg)
	if t == "string" then
		-- Strings are immutable so can be passed by reference, and cost their
		-- length plus the size of the Lua object header (24 bytes on a 64-bit
		-- platform) plus one byte for the NUL terminator.
		return msg, #msg + 25
	elseif t == "number" then
		-- Numbers are passed by value so need not be touched, and cost 8 bytes
		-- as all numbers in Lua are doubles.
		return msg, 8
	elseif t == "boolean" then
		-- Booleans are passed by value so need not be touched, and cost 1
		-- byte.
		return msg, 1
	elseif t == "table" then
		-- Tables are duplicated. Check if this table has been seen before
		-- (self-referential or shared table); if so, reuse the cleaned value
		-- of the previous occurrence, maintaining table topology and avoiding
		-- infinite recursion, and charge zero bytes for this as the object has
		-- already been counted.
		back_references = back_references or {}
		local bref = back_references[msg]
		if bref then
			return bref, 0
		end
		-- Construct a new table by cleaning all the keys and values and adding
		-- up their costs, plus 8 bytes as a rough estimate of table overhead.
		local cost = 8
		local ret = {}
		back_references[msg] = ret
		for k, v in pairs(msg) do
			local k_cost, v_cost
			k, k_cost = clean_and_weigh_digiline_message(k, back_references)
			v, v_cost = clean_and_weigh_digiline_message(v, back_references)
			if k ~= nil and v ~= nil then
				-- Only include an element if its key and value are of legal
				-- types.
				ret[k] = v
			end
			-- If we only counted the cost of a table element when we actually
			-- used it, we would be vulnerable to the following attack:
			-- 1. Construct a huge table (too large to pass the cost limit).
			-- 2. Insert it somewhere in a table, with a function as a key.
			-- 3. Insert it somewhere in another table, with a number as a key.
			-- 4. The first occurrence doesn’t pay the cost because functions
			--    are stripped and therefore the element is dropped.
			-- 5. The second occurrence doesn’t pay the cost because it’s in
			--    back_references.
			-- By counting the costs regardless of whether the objects will be
			-- included, we avoid this attack; it may overestimate the cost of
			-- some messages, but only those that won’t be delivered intact
			-- anyway because they contain illegal object types.
			cost = cost + k_cost + v_cost
		end
		return ret, cost
	else
		return nil, 0
	end
end


-- itbl: Flat table of functions to run after sandbox cleanup, used to prevent various security hazards
local function get_digiline_send(pos, itbl, send_warning)
	if not minetest.global_exists("digilines") then return end
	local chan_maxlen = mesecon.setting("luacontroller_digiline_channel_maxlen", 256)
	local maxlen = mesecon.setting("luacontroller_digiline_maxlen", 50000)
	return function(channel, msg)
		-- NOTE: This runs within string metatable sandbox, so don't *rely* on anything of the form (""):y
		--        or via anything that could.
		-- Make sure channel is string, number or boolean
		if type(channel) == "string" then
			if #channel > chan_maxlen then
				send_warning(S("Channel string too long."))
				return false
			end
		elseif (type(channel) ~= "string" and type(channel) ~= "number" and type(channel) ~= "boolean") then
			send_warning(S("Channel must be string, number or boolean."))
			return false
		end

		local msg_cost
		msg, msg_cost = clean_and_weigh_digiline_message(msg)
		if msg == nil or msg_cost > maxlen then
			send_warning(S("Message was too complex, or contained invalid data."))
			return false
		end

		table.insert(itbl, function ()
			-- Runs outside of string metatable sandbox
			local luac_id = minetest.get_meta(pos):get_int("luac_id")
			mesecon.queue:add_action(pos, "lc_digiline_relay", {channel, luac_id, msg})
		end)
		return true
	end
end

local safe_globals = {
	-- Don't add pcall/xpcall unless willing to deal with the consequences (unless very careful, incredibly likely to allow killing server indirectly)
	"assert", "error", "ipairs", "next", "pairs", "select",
	"tonumber", "tostring", "type", "unpack", "_VERSION"
}

local function create_environment(pos, mem, event, itbl, send_warning)
	-- Gather variables for the environment
	local vports = minetest.registered_nodes[minetest.get_node(pos).name].virtual_portstates
	local vports_copy = {}
	for k, v in pairs(vports) do vports_copy[k] = v end
	local rports = get_real_port_states(pos)

	-- Create new library tables on each call to prevent one Luacontroller
	-- from breaking a library and messing up other Luacontrollers.
	local env = {
		pin = merge_port_states(vports, rports),
		port = vports_copy,
		event = event,
		mem = mem,
		heat = mesecon.get_heat(pos),
		heat_max = mesecon.setting("overheat_max", 20),
		print = safe_print,
		interrupt = get_interrupt(pos, itbl, send_warning),
		digiline_send = get_digiline_send(pos, itbl, send_warning),
		string = {
			byte = string.byte,
			char = string.char,
			format = string.format,
			len = string.len,
			lower = string.lower,
			upper = string.upper,
			rep = safe_string_rep,
			reverse = string.reverse,
			sub = string.sub,
			find = safe_string_find,
		},
		math = {
			abs = math.abs,
			acos = math.acos,
			asin = math.asin,
			atan = math.atan,
			atan2 = math.atan2,
			ceil = math.ceil,
			cos = math.cos,
			cosh = math.cosh,
			deg = math.deg,
			exp = math.exp,
			floor = math.floor,
			fmod = math.fmod,
			frexp = math.frexp,
			huge = math.huge,
			ldexp = math.ldexp,
			log = math.log,
			log10 = math.log10,
			max = math.max,
			min = math.min,
			modf = math.modf,
			pi = math.pi,
			pow = math.pow,
			rad = math.rad,
			random = math.random,
			sin = math.sin,
			sinh = math.sinh,
			sqrt = math.sqrt,
			tan = math.tan,
			tanh = math.tanh,
		},
		table = {
			concat = table.concat,
			insert = table.insert,
			maxn = table.maxn,
			remove = table.remove,
			sort = table.sort,
		},
		os = {
			clock = os.clock,
			difftime = os.difftime,
			time = os.time,
			datetable = safe_date,
		},
	}
	env._G = env

	for _, name in pairs(safe_globals) do
		env[name] = _G[name]
	end

	return env
end


local function timeout()
	debug.sethook() -- Clear hook
	error("Code timed out!", 2)
end


local function create_sandbox(code, env)
	if code:byte(1) == 27 then
		return nil, "Binary code prohibited."
	end
	local f, msg = loadstring(code)
	if not f then return nil, msg end
	setfenv(f, env)

	-- Turn off JIT optimization for user code so that count
	-- events are generated when adding debug hooks
	if rawget(_G, "jit") then
		jit.off(f, true)
	end

	local maxevents = mesecon.setting("luacontroller_maxevents", 10000)
	return function(...)
		-- NOTE: This runs within string metatable sandbox, so the setting's been moved out for safety
		-- Use instruction counter to stop execution
		-- after luacontroller_maxevents
		debug.sethook(timeout, "", maxevents)
		local ok, ret = pcall(f, ...)
		debug.sethook()  -- Clear hook
		if not ok then error(ret, 0) end
		return ret
	end
end


local function load_memory(meta)
	return minetest.deserialize(meta:get_string("lc_memory"), true) or {}
end


local function save_memory(pos, meta, mem)
	local memstring = minetest.serialize(remove_functions(mem))
	local memsize_max = mesecon.setting("luacontroller_memsize", 100000)

	if (#memstring <= memsize_max) then
		meta:set_string("lc_memory", memstring)
		meta:mark_as_private("lc_memory")
	else
		print("Error: Luacontroller memory overflow. "..memsize_max.." bytes available, "
				..#memstring.." required. Controller overheats.")
		burn_controller(pos)
	end
end

-- Returns success (boolean), errmsg (string)
-- run (as opposed to run_inner) is responsible for setting up meta according to this output
local function run_inner(pos, code, event)
	local meta = minetest.get_meta(pos)
	-- Note: These return success, presumably to avoid changing LC ID.
	if overheat(pos) then return true, "" end
	if ignore_event(event, meta) then return true, "" end

	-- Load code & mem from meta
	local mem  = load_memory(meta)
	local code = meta:get_string("code")

	-- 'Last warning' label.
	local warning = ""
	local function send_warning(str)
		warning = S("Warning: @1", str)
	end

	-- Create environment
	local itbl = {}
	local env = create_environment(pos, mem, event, itbl, send_warning)

	-- Create the sandbox and execute code
	local f, msg = create_sandbox(code, env)
	if not f then return false, msg end
	-- Start string true sandboxing
	local onetruestring = getmetatable("")
	-- If a string sandbox is already up yet inconsistent, something is very wrong
	assert(onetruestring.__index == string)
	onetruestring.__index = env.string
	local success, msg = pcall(f)
	onetruestring.__index = string
	-- End string true sandboxing
	if not success then return false, msg end
	if type(env.port) ~= "table" then
		return false, S("Ports set are invalid.")
	end

	-- Actually set the ports
	set_port_states(pos, env.port)

	-- Save memory. This may burn the luacontroller if a memory overflow occurs.
	save_memory(pos, meta, env.mem)

	-- Execute deferred tasks
	for _, v in ipairs(itbl) do
		local failure = v()
		if failure then
			return false, failure
		end
	end
	return true, warning
end

local function reset_formspec(meta, code, errmsg)
	meta:set_string("code", code)
	meta:mark_as_private("code")
	code = minetest.formspec_escape(code or "")
	errmsg = minetest.formspec_escape(tostring(errmsg or ""))
	meta:set_string("formspec", "size[12,10]"
		.."background[-0.2,-0.25;12.4,10.75;jeija_luac_background.png]"
		.."label[5.5,-0.375;"..F(S("Luacontroller")).."]"
		.."label[0.1,8.3;"..errmsg.."]"
		.."textarea[0.2,0.2;12.2,9.5;code;;"..code.."]"
		.."button[4.75,8.75;2.5,1;program;"..F(S("Execute")).."]"
		.."image_button_exit[11.72,-0.25;0.425,0.4;jeija_close_window.png;exit;]"
		)
end

local function reset_meta(pos, code, errmsg)
	local meta = minetest.get_meta(pos)
	reset_formspec(meta, code, errmsg)
	meta:set_int("luac_id", math.random(1, 65535))
end

-- Wraps run_inner with LC-reset-on-error
local function run(pos, event)
	local meta = minetest.get_meta(pos)
	local code = meta:get_string("code")
	local ok, errmsg = run_inner(pos, code, event)
	if not ok then
		reset_meta(pos, code, errmsg)
	else
		reset_formspec(meta, code, errmsg)
	end
	return ok, errmsg
end

local function reset(pos)
	set_port_states(pos, {a=false, b=false, c=false, d=false})
end

local function node_timer(pos)
	if minetest.registered_nodes[minetest.get_node(pos).name].is_burnt then
		return false
	end
	run(pos, {type="interrupt"})
	return false
end

-----------------------
-- A.Queue callbacks --
-----------------------

mesecon.queue:add_function("lc_interrupt", function (pos, luac_id, iid)
	-- There is no luacontroller anymore / it has been reprogrammed / replaced / burnt
	if (minetest.get_meta(pos):get_int("luac_id") ~= luac_id) then return end
	if (minetest.registered_nodes[minetest.get_node(pos).name].is_burnt) then return end
	run(pos, {type="interrupt", iid = iid})
end)

mesecon.queue:add_function("lc_digiline_relay", function (pos, channel, luac_id, msg)
	if not digiline then return end
	-- This check is only really necessary because in case of server crash, old actions can be thrown into the future
	if (minetest.get_meta(pos):get_int("luac_id") ~= luac_id) then return end
	if (minetest.registered_nodes[minetest.get_node(pos).name].is_burnt) then return end
	-- The actual work
	digiline:receptor_send(pos, digiline.rules.default, channel, msg)
end)

-----------------------
-- Node Registration --
-----------------------

local output_rules = {}
local input_rules = {}

local node_box = {
	type = "fixed",
	fixed = {
		{-8/16, -8/16, -8/16, 8/16, -7/16, 8/16}, -- Bottom slab
		{-5/16, -7/16, -5/16, 5/16, -6/16, 5/16}, -- Circuit board
		{-3/16, -6/16, -3/16, 3/16, -5/16, 3/16}, -- IC
	}
}

local selection_box = {
	type = "fixed",
	fixed = { -8/16, -8/16, -8/16, 8/16, -5/16, 8/16 },
}

local digiline = {
	receptor = {},
	effector = {
		action = function(pos, node, channel, msg)
			msg = clean_and_weigh_digiline_message(msg)
			run(pos, {type = "digiline", channel = channel, msg = msg})
		end
	}
}

local function get_program(pos)
	local meta = minetest.get_meta(pos)
	return meta:get_string("code")
end

local function set_program(pos, code)
	reset(pos)
	reset_meta(pos, code)
	return run(pos, {type="program"})
end

local function on_receive_fields(pos, form_name, fields, sender)
	if not fields.program then
		return
	end
	local name = sender:get_player_name()
	if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass=true}) then
		minetest.record_protection_violation(pos, name)
		return
	end
	local ok, err = set_program(pos, fields.code)
	if not ok then
		-- it's not an error from the server perspective
		minetest.log("action", "Lua controller programming error: " .. tostring(err))
	end
end

for a = 0, 1 do -- 0 = off  1 = on
for b = 0, 1 do
for c = 0, 1 do
for d = 0, 1 do
	local cid = tostring(d)..tostring(c)..tostring(b)..tostring(a)
	local node_name = BASENAME..cid
	local top = "jeija_luacontroller_top.png"
	if a == 1 then
		top = top.."^jeija_luacontroller_LED_A.png"
	end
	if b == 1 then
		top = top.."^jeija_luacontroller_LED_B.png"
	end
	if c == 1 then
		top = top.."^jeija_luacontroller_LED_C.png"
	end
	if d == 1 then
		top = top.."^jeija_luacontroller_LED_D.png"
	end

	local groups
	if a + b + c + d ~= 0 then
		groups = {dig_immediate=2, not_in_creative_inventory=1, overheat = 1}
	else
		groups = {dig_immediate=2, overheat = 1}
	end

	output_rules[cid] = {}
	input_rules[cid] = {}
	if a == 1 then table.insert(output_rules[cid], rules.a) end
	if b == 1 then table.insert(output_rules[cid], rules.b) end
	if c == 1 then table.insert(output_rules[cid], rules.c) end
	if d == 1 then table.insert(output_rules[cid], rules.d) end

	if a == 0 then table.insert( input_rules[cid], rules.a) end
	if b == 0 then table.insert( input_rules[cid], rules.b) end
	if c == 0 then table.insert( input_rules[cid], rules.c) end
	if d == 0 then table.insert( input_rules[cid], rules.d) end

	local mesecons = {
		effector = {
			rules = input_rules[cid],
			action_change = function (pos, _, rule_name, new_state)
				update_real_port_states(pos, rule_name, new_state)
				run(pos, {type=new_state, pin=rule_name})
			end,
		},
		receptor = {
			state = mesecon.state.on,
			rules = output_rules[cid]
		},
		luacontroller = {
			get_program = get_program,
			set_program = set_program,
		},
	}

	minetest.register_node(node_name, {
		description = S("Luacontroller"),
		drawtype = "nodebox",
		tiles = {
			top,
			"jeija_microcontroller_bottom.png",
			"jeija_microcontroller_sides.png",
			"jeija_microcontroller_sides.png",
			"jeija_microcontroller_sides.png",
			"jeija_microcontroller_sides.png"
		},
		inventory_image = top,
		paramtype = "light",
		is_ground_content = false,
		groups = groups,
		drop = BASENAME.."0000",
		sunlight_propagates = true,
		selection_box = selection_box,
		node_box = node_box,
		on_construct = reset_meta,
		on_receive_fields = on_receive_fields,
		sounds = default.node_sound_stone_defaults(),
		mesecons = mesecons,
		digiline = digiline,
		-- Virtual portstates are the ports that
		-- the node shows as powered up (light up).
		virtual_portstates = {
			a = a == 1,
			b = b == 1,
			c = c == 1,
			d = d == 1,
		},
		after_dig_node = function (pos, node)
			mesecon.do_cooldown(pos)
			mesecon.receptor_off(pos, output_rules)
		end,
		is_luacontroller = true,
		on_timer = node_timer,
		on_blast = mesecon.on_blastnode,
	})
end
end
end
end

------------------------------
-- Overheated Luacontroller --
------------------------------

minetest.register_node(BASENAME .. "_burnt", {
	drawtype = "nodebox",
	tiles = {
		"jeija_luacontroller_burnt_top.png",
		"jeija_microcontroller_bottom.png",
		"jeija_microcontroller_sides.png",
		"jeija_microcontroller_sides.png",
		"jeija_microcontroller_sides.png",
		"jeija_microcontroller_sides.png"
	},
	inventory_image = "jeija_luacontroller_burnt_top.png",
	is_burnt = true,
	paramtype = "light",
	is_ground_content = false,
	groups = {dig_immediate=2, not_in_creative_inventory=1},
	drop = BASENAME.."0000",
	sunlight_propagates = true,
	selection_box = selection_box,
	node_box = node_box,
	on_construct = reset_meta,
	on_receive_fields = on_receive_fields,
	sounds = default.node_sound_stone_defaults(),
	virtual_portstates = {a = false, b = false, c = false, d = false},
	mesecons = {
		effector = {
			rules = mesecon.rules.flat,
			action_change = function(pos, _, rule_name, new_state)
				update_real_port_states(pos, rule_name, new_state)
			end,
		},
	},
	on_blast = mesecon.on_blastnode,
})

------------------------
-- Craft Registration --
------------------------

minetest.register_craft({
	output = BASENAME.."0000 2",
	recipe = {
		{'mesecons_materials:silicon', 'mesecons_materials:silicon', 'group:mesecon_conductor_craftable'},
		{'mesecons_materials:silicon', 'mesecons_materials:silicon', 'group:mesecon_conductor_craftable'},
		{'group:mesecon_conductor_craftable', 'group:mesecon_conductor_craftable', ''},
	}
})

