local S = minetest.get_translator("mesecons_movestone")

-- MOVESTONE
-- Non-sticky:
-- Moves along mesecon lines
-- Pushes all blocks in front of it
--
-- Sticky one
-- Moves along mesecon lines
-- Pushes all block in front of it
-- Pull all blocks in its back

-- settings:
local timer_interval = 1 / mesecon.setting("movestone_speed", 3)
local max_push = mesecon.setting("movestone_max_push", 50)
local max_pull = mesecon.setting("movestone_max_pull", 50)

-- helper functions:
local function get_movestone_direction(rulename, is_vertical)
	if is_vertical then
		if rulename.z > 0 then
			return {x = 0, y = -1, z = 0}
		elseif rulename.z < 0 then
			return {x = 0, y = 1, z = 0}
		elseif rulename.x > 0 then
			return {x = 0, y = -1, z = 0}
		elseif rulename.x < 0 then
			return {x = 0, y = 1, z = 0}
		end
	else
		if rulename.z > 0 then
			return {x = -1, y = 0, z = 0}
		elseif rulename.z < 0 then
			return {x = 1, y = 0, z = 0}
		elseif rulename.x > 0 then
			return {x = 0, y = 0, z = -1}
		elseif rulename.x < 0 then
			return {x = 0, y = 0, z = 1}
		end
	end
end

-- registration functions:
function mesecon.register_movestone(name, def, is_sticky, is_vertical)
	local function movestone_move(pos, node, rulename)
		local direction = get_movestone_direction(rulename, is_vertical)
		local frontpos = vector.add(pos, direction)
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("owner")

		-- ### Step 1: Push nodes in front ###
		local success, stack, oldstack = mesecon.mvps_push(frontpos, direction, max_push, owner)
		if not success then
			if stack == "protected" then
				meta:set_string("infotext", "Can't move: protected area on the way")
				return
			end
			minetest.get_node_timer(pos):start(timer_interval)
			return
		end
		mesecon.mvps_move_objects(frontpos, direction, oldstack)

		-- ### Step 2: Move the movestone ###
		minetest.set_node(frontpos, node)
		local meta2 = minetest.get_meta(frontpos)
		meta2:set_string("owner", owner)
		minetest.remove_node(pos)
		mesecon.on_dignode(pos, node)
		mesecon.on_placenode(frontpos, node)
		minetest.get_node_timer(frontpos):start(timer_interval)

		-- ### Step 3: If sticky, pull stack behind ###
		if is_sticky then
			local backpos = vector.subtract(pos, direction)
			success, stack, oldstack = mesecon.mvps_pull_all(backpos, direction, max_pull, owner)
			if success then
				mesecon.mvps_move_objects(backpos, vector.multiply(direction, -1), oldstack, -1)
			end
		end

		-- ### Step 4: Let things fall ###
		minetest.check_for_falling(vector.add(pos, {x=0, y=1, z=0}))
	end

	def.is_ground_content = false

	def.mesecons = {effector = {
		action_on = function(pos, node, rulename)
			if rulename and not minetest.get_node_timer(pos):is_started() then
				movestone_move(pos, node, rulename)
			end
		end,
		rules = mesecon.rules.default,
	}}

	def.after_place_node = mesecon.mvps_set_owner

	def.on_punch = function(pos, node, player)
		local player_name = player and player.get_player_name and player:get_player_name()
		if mesecon.mvps_claim(pos, player_name) then
			minetest.get_node_timer(pos):start(timer_interval)
			minetest.chat_send_player(player_name, "Reclaimed movestone")
		end
	end

	def.on_timer = function(pos, elapsed)
		local sourcepos = mesecon.is_powered(pos)
		if not sourcepos then
			return
		end
		local rulename = vector.subtract(sourcepos[1], pos)
		mesecon.activate(pos, minetest.get_node(pos), rulename, 0)
	end

	def.on_blast = mesecon.on_blastnode

	minetest.register_node(name, def)
end


-- registration:
mesecon.register_movestone("mesecons_movestones:movestone", {
	tiles = {
		"jeija_movestone_side.png",
		"jeija_movestone_side.png",
		"jeija_movestone_arrows.png^[transformFX",
		"jeija_movestone_arrows.png^[transformFX",
		"jeija_movestone_arrows.png",
		"jeija_movestone_arrows.png",
	},
	groups = {cracky = 3},
    description = S("Movestone"),
	sounds = default.node_sound_stone_defaults()
}, false, false)

mesecon.register_movestone("mesecons_movestones:sticky_movestone", {
	tiles = {
		"jeija_movestone_side.png",
		"jeija_movestone_side.png",
		"jeija_sticky_movestone.png^[transformFX",
		"jeija_sticky_movestone.png^[transformFX",
		"jeija_sticky_movestone.png",
		"jeija_sticky_movestone.png",
	},
	groups = {cracky = 3},
    description = S("Sticky Movestone"),
	sounds = default.node_sound_stone_defaults(),
}, true, false)

mesecon.register_movestone("mesecons_movestones:movestone_vertical", {
	tiles = {
		"jeija_movestone_side.png",
		"jeija_movestone_side.png",
		"jeija_movestone_arrows.png^[transformFXR90",
		"jeija_movestone_arrows.png^[transformR90",
		"jeija_movestone_arrows.png^[transformFXR90",
		"jeija_movestone_arrows.png^[transformR90",
	},
	groups = {cracky = 3},
    description = S("Vertical Movestone"),
	sounds = default.node_sound_stone_defaults()
}, false, true)

mesecon.register_movestone("mesecons_movestones:sticky_movestone_vertical", {
	tiles = {
		"jeija_movestone_side.png^(mesecons_glue.png^[opacity:127)",
		"jeija_movestone_side.png^(mesecons_glue.png^[opacity:127)",
		"jeija_movestone_arrows.png^[transformFXR90",
		"jeija_movestone_arrows.png^[transformR90",
		"jeija_movestone_arrows.png^[transformFXR90",
		"jeija_movestone_arrows.png^[transformR90",
	},
	groups = {cracky = 3},
    description = S("Vertical Sticky Movestone"),
	sounds = default.node_sound_stone_defaults(),
}, true, true)


-- crafting:
-- base recipe:
minetest.register_craft({
	output = "mesecons_movestones:movestone 2",
	recipe = {
		{"default:stone", "default:stone", "default:stone"},
		{"group:mesecon_conductor_craftable", "group:mesecon_conductor_craftable", "group:mesecon_conductor_craftable"},
		{"default:stone", "default:stone", "default:stone"},
	}
})

-- conversation:
minetest.register_craft({
	type = "shapeless",
	output = "mesecons_movestones:movestone",
	recipe = {"mesecons_movestones:movestone_vertical"},
})

minetest.register_craft({
	type = "shapeless",
	output = "mesecons_movestones:movestone_vertical",
	recipe = {"mesecons_movestones:movestone"},
})

minetest.register_craft({
	type = "shapeless",
	output = "mesecons_movestones:sticky_movestone",
	recipe = {"mesecons_movestones:sticky_movestone_vertical"},
})

minetest.register_craft({
	type = "shapeless",
	output = "mesecons_movestones:sticky_movestone_vertical",
	recipe = {"mesecons_movestones:sticky_movestone"},
})

-- make sticky:
minetest.register_craft({
	output = "mesecons_movestones:sticky_movestone",
	recipe = {
		{"mesecons_materials:glue", "mesecons_movestones:movestone", "mesecons_materials:glue"},
	}
})

minetest.register_craft({
	output = "mesecons_movestones:sticky_movestone_vertical",
	recipe = {
		{"mesecons_materials:glue"},
		{"mesecons_movestones:movestone_vertical"},
		{"mesecons_materials:glue"},
	}
})


-- legacy code:
minetest.register_alias("mesecons_movestones:movestone_active",
		"mesecons_movestones:movestone")
minetest.register_alias("mesecons_movestones:sticky_movestone_active",
		"mesecons_movestones:sticky_movestone")
