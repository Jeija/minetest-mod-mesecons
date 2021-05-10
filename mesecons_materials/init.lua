-- Glue and fiber
minetest.register_craftitem("mesecons_materials:glue", {
	image = "mesecons_glue.png",
	on_place_on_ground = minetest.craftitem_place_item,
    	description="Glue",
})

minetest.register_craftitem("mesecons_materials:fiber", {
	image = "mesecons_fiber.png",
	on_place_on_ground = minetest.craftitem_place_item,
    	description="Fiber",
})

minetest.register_craft({
	output = "mesecons_materials:glue 2",
	type = "cooking",
	recipe = "group:sapling",
	cooktime = 2
})

minetest.register_craft({
	output = "mesecons_materials:fiber 6",
	type = "cooking",
	recipe = "mesecons_materials:glue",
	cooktime = 4
})

-- Silicon
minetest.register_craftitem("mesecons_materials:silicon", {
	image = "mesecons_silicon.png",
	on_place_on_ground = minetest.craftitem_place_item,
    	description="Silicon",
})

minetest.register_craft({
	output = "mesecons_materials:silicon 4",
	recipe = {
		{"group:sand", "group:sand"},
		{"group:sand", "default:mese_crystal"},
	}
})
