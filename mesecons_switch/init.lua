local S = minetest.get_translator("mesecons_switch")

-- mesecons_switch

mesecon.register_node("mesecons_switch:mesecon_switch", {
	paramtype2="facedir",
	description=S("Switch"),
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	on_rightclick = function (pos, node)
		if(mesecon.flipstate(pos, node) == "on") then
			mesecon.receptor_on(pos)
		else
			mesecon.receptor_off(pos)
		end
		minetest.sound_play("mesecons_switch", {pos=pos})
	end
},{
	groups = {dig_immediate=2},
	tiles = {	"mesecons_switch_side.png", "mesecons_switch_side.png",
				"mesecons_switch_side.png", "mesecons_switch_side.png",
				"mesecons_switch_side.png", "mesecons_switch_off.png"},
	mesecons = {receptor = { state = mesecon.state.off }}
},{
	groups = {dig_immediate=2, not_in_creative_inventory=1},
	tiles = {	"mesecons_switch_side.png", "mesecons_switch_side.png",
				"mesecons_switch_side.png", "mesecons_switch_side.png",
				"mesecons_switch_side.png", "mesecons_switch_on.png"},
	mesecons = {receptor = { state = mesecon.state.on }}
})

minetest.register_craft({
	output = "mesecons_switch:mesecon_switch_off 2",
	recipe = {
		{"default:steel_ingot", "default:cobble", "default:steel_ingot"},
		{"group:mesecon_conductor_craftable","", "group:mesecon_conductor_craftable"},
	}
})
