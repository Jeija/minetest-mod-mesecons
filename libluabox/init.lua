libluabox = {}
--local lualua = require("lualua")
local path = minetest.get_modpath("libluabox")
local lualua = package.loadlib(path .. "/lualua.so", "luaopen_lualua")
libluabox.run = lualua()
