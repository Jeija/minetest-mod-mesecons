mem = (...) or {}

log = {}

function print(...)
	local entry = {}
	for i, v in ipairs({...}) do
		entry[i] = dump(v)
	end
	log[#log + 1] = table.concat(entry, "\t")
end
