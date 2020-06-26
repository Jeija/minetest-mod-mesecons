local BASE = minetest.get_modpath(minetest.get_current_modname())
local LIBS = BASE .. "/sandbox"

local function load_lib(name)
	local filename = string.format("%s/%s.lua", LIBS, name)
	local file = io.open(filename, "rb")
	local code = file:read("*a")
	file:close()
	return code
end

local f_init = load_lib("_init")
local f_fini = load_lib("_fini")
local l_helpers = load_lib("helpers")
local l_serialize = load_lib("serialize")
local c_test = load_lib("test")

local function b(value)
	if value then
		return "true"
	end
	return "false"
end

local function serialize_ports(key, port)
	return string.format("%s = {a=%s, b=%s, c=%s, d=%s}", key, b(port.a), b(port.b), b(port.c), b(port.d))
end

function mesecons_sandbox.run(pin, port, mem, code)
	print("Old ports:", dump(port))
	print("Old memory:", mem)
	print("Code:", code)
	local ok, port, mem, log = libluabox.run(1.0, 128, l_helpers, l_serialize,
		serialize_ports("pin", pin),
		serialize_ports("port", port),
		mem,
		f_init, code, f_fini)
	print(minetest.serialize({ok, port, mem, log}))
	if ok then
		print("New memory:", mem)
		print("New ports:", port)
	end
	if log then
		print("Log: <<<")
		print(log)
		print(">>>")
	end
	return ok, minetest.deserialize(port, true), (mem or "")
end
