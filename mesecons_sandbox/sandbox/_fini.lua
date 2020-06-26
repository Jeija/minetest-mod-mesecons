local port = serialize(port)
local mem = serialize(mem)
local log = table.concat(log, "\n")
return port, mem, log
