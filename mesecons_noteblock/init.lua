local S = minetest.get_translator("mesecons_noteblock")

minetest.register_node("mesecons_noteblock:noteblock", {
	description = S("Noteblock"),
	tiles = {"mesecons_noteblock.png"},
	is_ground_content = false,
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2},
	on_punch = function(pos, node) -- change sound when punched
		node.param2 = (node.param2+1)%12
		mesecon.noteblock_play(pos, node.param2)
		minetest.set_node(pos, node)
	end,
	sounds = default.node_sound_wood_defaults(),
	mesecons = {effector = { -- play sound when activated
		action_on = function(pos, node)
			mesecon.noteblock_play(pos, node.param2)
		end
	}},
	on_blast = mesecon.on_blastnode,
})

minetest.register_craft({
	output = "mesecons_noteblock:noteblock 1",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:mesecon_conductor_craftable", "default:steel_ingot", "group:mesecon_conductor_craftable"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

local soundnames = {
	[0] = "mesecons_noteblock_csharp",
	"mesecons_noteblock_d",
	"mesecons_noteblock_dsharp",
	"mesecons_noteblock_e",
	"mesecons_noteblock_f",
	"mesecons_noteblock_fsharp",
	"mesecons_noteblock_g",
	"mesecons_noteblock_gsharp",

	"mesecons_noteblock_a",
	"mesecons_noteblock_asharp",
	"mesecons_noteblock_b",
	"mesecons_noteblock_c"
}

local node_sounds = {
	["default:glass"] = "mesecons_noteblock_hihat",
	["default:stone"] = "mesecons_noteblock_kick",
	["default:lava_source"] = "fire_fire",
	["default:chest"] = "mesecons_noteblock_snare",
	["default:tree"] = "mesecons_noteblock_crash",
	["default:wood"] = "mesecons_noteblock_litecrash",
	["default:coalblock"] = "tnt_explode",
}

mesecon.noteblock_play = function(pos, param2)
	pos.y = pos.y-1
	local nodeunder = minetest.get_node(pos).name
	local soundname = node_sounds[nodeunder]
	if not soundname then
		soundname = soundnames[param2]
		if not soundname then
			minetest.log("error", "[mesecons_noteblock] No soundname found, test param2")
			return
		end
		if nodeunder == "default:steelblock" then
			soundname = soundname.. 2
		end
	end
	pos.y = pos.y+1
	minetest.sound_play(soundname, {pos = pos})
end
