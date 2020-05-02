local S = minetest.get_translator("mesecons_fpga")

local lg = {}

local operations = {
	-- table index: Index in the formspec dropdown
	-- gate:    Internal name
	-- short:   Serialized form, single character
	-- fs_name: Display name, padded to 4 characters
	-- func:    Function that applies the operation
	-- unary:   Whether this gate only has one input
	{ gate = "and",  short = "&", fs_name = " AND", func = function(a, b) return a and b end },
	{ gate = "or",   short = "|", fs_name = "  OR", func = function(a, b) return a or b end },
	{ gate = "not",  short = "~", fs_name = " NOT", func = function(a, b) return not b end, unary = true },
	{ gate = "xor",  short = "^", fs_name = " XOR", func = function(a, b) return a ~= b end },
	{ gate = "nand", short = "?", fs_name = "NAND", func = function(a, b) return not (a and b) end },
	{ gate = "buf",  short = "_", fs_name = "   =", func = function(a, b) return b end, unary = true },
	{ gate = "xnor", short = "=", fs_name = "XNOR", func = function(a, b) return a == b end },
	{ gate = "nor",  short = "!", fs_name = " NOR", func = function(a, b) return not (a or b) end },
}

lg.get_operations = function()
	return operations
end

-- (de)serialize
lg.serialize = function(t)
	local function _op(t)
		if t == nil then
			return " "
		elseif t.type == "io" then
			return t.port
		else -- t.type == "reg"
			return tostring(t.n)
		end
	end
	-- Serialize actions (gates) from eg. "and" to "&"
	local function _action(action)
		for i, data in ipairs(operations) do
			if data.gate == action then
				return data.short
			end
		end
		return " "
	end

	local s = ""
	for i = 1, 14 do
		local cur = t[i]
		if next(cur) ~= nil then
			s = s .. _op(cur.op1) .. _action(cur.action) .. _op(cur.op2) .. _op(cur.dst)
		end
		s = s .. "/"
	end
	return s
end

lg.deserialize = function(s)
	local function _op(c)
		if c == "A" or c == "B" or c == "C" or c == "D" then
			return {type = "io", port = c}
		elseif c == " " then
			return nil
		else
			return {type = "reg", n = tonumber(c)}
		end
	end
	-- Deserialize actions (gates) from eg. "&" to "and"
	local function _action(action)
		for i, data in ipairs(operations) do
			if data.short == action then
				return data.gate
			end
		end
		-- nil
	end

	local ret = {}
	for part in s:gmatch("(.-)/") do
		local parsed
		if part == "" then
			parsed = {}
		else
			parsed = {
				action = _action( part:sub(2,2) ),
				op1 = _op( part:sub(1,1) ),
				op2 = _op( part:sub(3,3) ),
				dst = _op( part:sub(4,4) ),
			}
		end
		ret[#ret + 1] = parsed
	end
	-- More than 14 instructions (write to all 10 regs + 4 outputs)
	-- will not pass the write-once requirement of the validator
	assert(#ret == 14)
	return ret
end

-- validation
lg.validate_single = function(t, i)
	local function is_reg_written_to(t, n, max)
		for i = 1, max-1 do
			if next(t[i]) ~= nil
					and t[i].dst and t[i].dst.type == "reg"
					and t[i].dst.n == n then
				return true
			end
		end
		return false
	end
	local function compare_op(t1, t2, allow_same_io)
		if t1 == nil or t2 == nil then
			return false
		elseif t1.type ~= t2.type then
			return false
		end
		if t1.type == "reg" and t1.n == t2.n then
			return true
		elseif t1.type == "io" and t1.port == t2.port then
			return not allow_same_io
		end
		return false
	end
	local elem = t[i]

	local gate_data
	for j, data in ipairs(operations) do
		if data.gate == elem.action then
			gate_data = data
			break
		end
	end

	-- check for completeness
	if not gate_data then
		return {i = i, msg = S("Gate type is required")}
	elseif gate_data.unary then
		if elem.op1 ~= nil or elem.op2 == nil or elem.dst == nil then
			return {i = i, msg = S("Second operand (only) and destination are required")}
		end
	else
		if elem.op1 == nil or elem.op2 == nil or elem.dst == nil then
			return {i = i, msg = S("Operands and destination are required")}
		end
	end
	-- check whether operands/destination are identical
	if compare_op(elem.op1, elem.op2) then
		return {i = i, msg = S("Operands cannot be identical")}
	end
	if compare_op(elem.op1, elem.dst, true) or compare_op(elem.op2, elem.dst, true) then
		return {i = i, msg = S("Destination and operands must be different")}
	end
	-- check whether operands point to defined registers
	if elem.op1 ~= nil and elem.op1.type == "reg"
			and not is_reg_written_to(t, elem.op1.n, i) then
		return {i = i, msg = S("First operand is undefined register")}
	end
	if elem.op2.type == "reg" and not is_reg_written_to(t, elem.op2.n, i) then
		return {i = i, msg = S("Second operand is undefined register")}
	end
	-- check whether destination points to undefined register
	if elem.dst.type == "reg" and is_reg_written_to(t, elem.dst.n, i) then
		return {i = i, msg = S("Destination is already used register")}
	end

	return nil
end

lg.validate = function(t)
	for i = 1, 14 do
		if next(t[i]) ~= nil then
			local r = lg.validate_single(t, i)
			if r ~= nil then
				return r
			end
		end
	end
	return nil
end

-- interpreter
lg.interpret = function(t, a, b, c, d)
	local function _action(s, v1, v2)
		for i, data in ipairs(operations) do
			if data.gate == s then
				return data.func(v1, v2)
			end
		end
		return false -- unknown gate
	end
	local function _op(t, regs, io_in)
		if t.type == "reg" then
			return regs[t.n]
		else -- t.type == "io"
			return io_in[t.port]
		end
	end

	local io_in = {A=a, B=b, C=c, D=d}
	local regs = {}
	local io_out = {}
	for i = 1, 14 do
		local cur = t[i]
		if next(cur) ~= nil then
			local v1, v2
			if cur.op1 ~= nil then
				v1 = _op(cur.op1, regs, io_in)
			end
			v2 = _op(cur.op2, regs, io_in)

			local result = _action(cur.action, v1, v2)

			if cur.dst.type == "reg" then
				regs[cur.dst.n] = result
			else -- cur.dst.type == "io"
				io_out[cur.dst.port] = result
			end
		end
	end
	return io_out.A, io_out.B, io_out.C, io_out.D
end

return lg
