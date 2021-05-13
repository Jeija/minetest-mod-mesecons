minetest.register_node("mesecons_noteblock:noteblock", {
	description = "Noteblock",
	tiles = {"mesecons_noteblock.png"},
	is_ground_content = false,
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2},
	on_punch = function(pos, node, puncher) -- change sound when punched
		if minetest.is_protected(pos, puncher and puncher:get_player_name() or "") then
			return
		end

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
	place_param2 = 11, -- initialize at C note
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
	"mesecons_noteblock_c" -- << noteblock is initialized here
}

local node_sounds = {
	["default:lava_source"] = "fire_fire",
	["default:chest"] = "mesecons_noteblock_snare",
	["default:chest_locked"] = "mesecons_noteblock_snare",
	["default:coalblock"] = "tnt_explode",
	["default:glass"] = "mesecons_noteblock_hihat",
	["default:obsidian_glass"] = "mesecons_noteblock_hihat",
}

local node_sounds_group = {
	["stone"] = "mesecons_noteblock_kick",
	["tree"] = "mesecons_noteblock_crash",
	["wood"] = "mesecons_noteblock_litecrash",
}

mesecon.noteblock_play = function(pos, param2)
	pos.y = pos.y-1
	local nodeunder = minetest.get_node(pos).name
	local soundname = node_sounds[nodeunder]
	local pitch
	-- Special sounds
	if not soundname then
		for k,v in pairs(node_sounds_group) do
			local g = minetest.get_item_group(nodeunder, k)
			if g ~= 0 then
				soundname = v
				break
			end
		end
	end
	-- Piano
	if not soundname then
		for k,v in pairs(node_sounds_group) do
			local g = minetest.get_item_group(nodeunder, k)
			if g ~= 0 then
				soundname = v
				break
			end
		end
	end
	if not soundname then
		soundname = soundnames[param2]
		if not soundname then
			minetest.log("error", "[mesecons_noteblock] No soundname found, test param2")
			return
		end
		if nodeunder == "default:steelblock" then
			soundname = soundname.. 2
		end
		pitch = false
	end
	-- Disable pitch for fire and explode because they'd sound too odd
	if soundname == "fire_fire" or soundname == "tnt_explode" then
		pitch = false
	end
	if pitch == false then
		pitch = nil
	else
		-- Calculate pitch
		local val = (param2+1)%12
		-- All semitones from C to B (analog to piano mode)
		pitch = 2^((val-6)/12)
	end
	pos.y = pos.y+1
	if soundname == "fire_fire" then
		-- Smoothly fade out fire sound
		local handle = minetest.sound_play(soundname, {pos = pos, loop = true})
		minetest.after(3.0, minetest.sound_fade, handle, -1.5, 0.0)
	else
		minetest.sound_play(soundname, {pos = pos, pitch = pitch}, true)
	end
end
