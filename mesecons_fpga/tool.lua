local S = minetest.get_translator("mesecons_fpga")

return function(plg)


minetest.register_tool("mesecons_fpga:programmer", {
	description = S("FPGA Programmer"),
	inventory_image = "jeija_fpga_programmer.png",
	stack_max = 1,
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end

		local pos = pointed_thing.under
		if minetest.get_node(pos).name:find("mesecons_fpga:fpga") ~= 1 then
			return itemstack
		end

		local meta = minetest.get_meta(pos)
		if meta:get_string("instr") == "//////////////" then
			minetest.chat_send_player(placer:get_player_name(), S("This FPGA is unprogrammed."))
			return itemstack
		end
		itemstack:set_metadata(meta:get_string("instr"))
		minetest.chat_send_player(placer:get_player_name(), S("FPGA gate configuration was successfully copied!"))

		return itemstack
	end,
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end

		local pos = pointed_thing.under
		if minetest.get_node(pos).name:find("mesecons_fpga:fpga") ~= 1 then
			return itemstack
		end
		local player_name = user:get_player_name()
		if minetest.is_protected(pos, player_name) then
			minetest.record_protection_violation(pos, player_name)
			return itemstack
		end

		local imeta = itemstack:get_metadata()
		if imeta == "" then
			minetest.chat_send_player(player_name, S("Use shift+right-click to copy a gate configuration first."))
			return itemstack
		end

		local meta = minetest.get_meta(pos)
		meta:set_string("instr", imeta)
		plg.update_meta(pos, imeta)
		minetest.chat_send_player(player_name, S("Gate configuration was successfully written to FPGA!"))

		return itemstack
	end
})

minetest.register_craft({
	output = "mesecons_fpga:programmer",
	recipe = {
		{'group:mesecon_conductor_craftable'},
		{'mesecons_materials:silicon'},
	}
})


end
