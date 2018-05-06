local S = technic.getter

local fs_helpers = pipeworks.fs_helpers

local function round(v)
	return math.floor(v + 0.5)
end

function register_base_machine(data)
	local typename = data.typename
	local input_size = technic.recipes[typename].input_size
	local machine_name = data.machine_name
	local machine_desc = data.machine_desc
	local tier = data.tier
	local ltier = string.lower(tier)

	local groups = {cracky = 2, technic_machine = 1, ["technic_"..ltier] = 1}
	if data.tube then
		groups.tubedevice = 1
		groups.tubedevice_receiver = 1
	end
	local active_groups = {not_in_creative_inventory = 1}
	for k, v in pairs(groups) do active_groups[k] = v end

	local formspec =
		"invsize[8,9;]"..
		"list[current_name;src;"..(4-input_size)..",1;"..input_size..",1;]"..
		"list[current_name;dst;5,1;2,2;]"..
		"list[current_player;main;0,5;8,4;]"..
		"label[0,0;"..machine_desc:format(tier).."]"..
		"listring[current_name;dst]"..
		"listring[current_player;main]"..
		"listring[current_name;src]"..
		"listring[current_player;main]"
	if data.upgrade then
		formspec = formspec..
			"list[current_name;upgrade1;1,3;1,1;]"..
			"list[current_name;upgrade2;2,3;1,1;]"..
			"label[1,4;"..S("Upgrade Slots").."]"..
			"listring[current_name;upgrade1]"..
			"listring[current_player;main]"..
			"listring[current_name;upgrade2]"..
			"listring[current_player;main]"
	end

	local run = function(pos, node)
		local meta     = minetest.get_meta(pos)
		local inv      = meta:get_inventory()
		local eu_input = meta:get_int(tier.."_EU_input")

		local machine_desc_tier = machine_desc:format(tier)
		local machine_node      = "technic_recycler:"..ltier.."_"..machine_name
		local machine_demand    = data.demand

		-- Setup meta data if it does not exist.
		if not eu_input then
			meta:set_int(tier.."_EU_demand", machine_demand[1])
			meta:set_int(tier.."_EU_input", 0)
			return
		end

		local EU_upgrade, tube_upgrade = 0, 0
		if data.upgrade then
			EU_upgrade, tube_upgrade = technic.handle_machine_upgrades(meta)
		end
		if data.tube then
			technic.handle_machine_pipeworks(pos, tube_upgrade)
		end

		local powered = eu_input >= machine_demand[EU_upgrade+1]
		if powered then
			meta:set_int("src_time", meta:get_int("src_time") + round(data.speed*10))
		end
		while true do
			local result = technic.get_recipe(typename, inv:get_list("src"))
			if not result then
				technic.swap_node(pos, machine_node)
				meta:set_string("infotext", S("%s Idle"):format(machine_desc_tier))
				meta:set_int(tier.."_EU_demand", 0)
				meta:set_int("src_time", 0)
				return
			end
			meta:set_int(tier.."_EU_demand", machine_demand[EU_upgrade+1])
			technic.swap_node(pos, machine_node.."_active")
			meta:set_string("infotext", S("%s Active"):format(machine_desc_tier))
			if meta:get_int("src_time") < round(result.time*10) then
				if not powered then
					technic.swap_node(pos, machine_node)
					meta:set_string("infotext", S("%s Unpowered"):format(machine_desc_tier))
				end
				return
			end
			local output = result.output
			if type(output) ~= "table" then output = { output } end
			local output_stacks = {}
			for _, o in ipairs(output) do
				table.insert(output_stacks, ItemStack(o))
			end
			local room_for_output = true
			inv:set_size("dst_tmp", inv:get_size("dst"))
			inv:set_list("dst_tmp", inv:get_list("dst"))
			for _, o in ipairs(output_stacks) do
				if not inv:room_for_item("dst_tmp", o) then
					room_for_output = false
					break
				end
				inv:add_item("dst_tmp", o)
			end
			if not room_for_output then
				technic.swap_node(pos, machine_node)
				meta:set_string("infotext", S("%s Idle"):format(machine_desc_tier))
				meta:set_int(tier.."_EU_demand", 0)
				meta:set_int("src_time", round(result.time*10))
				return
			end
			meta:set_int("src_time", meta:get_int("src_time") - round(result.time*10))
			inv:set_list("src", result.new_input)
			inv:set_list("dst", inv:get_list("dst_tmp"))
		end
	end

	local tentry = tube_entry
	if ltier == "lv" then
		tentry = ""
	end
	minetest.register_node("technic_recycler:"..ltier.."_"..machine_name, {
		description = machine_desc:format(tier),
		tiles = {
			"technic_"..ltier.."_"..machine_name.."_top.png"..tentry, 
			"technic_"..ltier.."_"..machine_name.."_bottom.png"..tentry,
			"technic_"..ltier.."_"..machine_name.."_side.png"..tentry,
			"technic_"..ltier.."_"..machine_name.."_side.png"..tentry,
			"technic_"..ltier.."_"..machine_name.."_side.png"..tentry,
			"technic_"..ltier.."_"..machine_name.."_front.png"
		},
		paramtype2 = "facedir",
		groups = groups,
		tube = data.tube and tube or nil,
		connect_sides = data.connect_sides or connect_default,
		legacy_facedir_simple = true,
		sounds = default.node_sound_wood_defaults(),
		on_construct = function(pos)
			local node = minetest.get_node(pos)
			local meta = minetest.get_meta(pos)

			local form_buttons = ""
			if not string.find(node.name, ":lv_") then
				form_buttons = fs_helpers.cycling_button(
					meta,
					pipeworks.button_base,
					"splitstacks",
					{
						pipeworks.button_off,
						pipeworks.button_on
					}
				)..pipeworks.button_label
			end

			meta:set_string("infotext", machine_desc:format(tier))
			meta:set_int("tube_time",  0)
			meta:set_string("formspec", formspec..form_buttons)
			local inv = meta:get_inventory()
			inv:set_size("src", input_size)
			inv:set_size("dst", 4)
			inv:set_size("upgrade1", 1)
			inv:set_size("upgrade2", 1)
		end,
		can_dig = technic.machine_can_dig,
		allow_metadata_inventory_put = technic.machine_inventory_put,
		allow_metadata_inventory_take = technic.machine_inventory_take,
		allow_metadata_inventory_move = technic.machine_inventory_move,
		technic_run = run,
		after_place_node = data.tube and pipeworks.after_place,
		after_dig_node = technic.machine_after_dig_node,
		on_receive_fields = function(pos, formname, fields, sender)
			local node = minetest.get_node(pos)
			if not pipeworks.may_configure(pos, sender) then return end
			fs_helpers.on_receive_fields(pos, fields)
			local meta = minetest.get_meta(pos)
			local form_buttons = ""
			if not string.find(node.name, ":lv_") then
				form_buttons = fs_helpers.cycling_button(
					meta,
					pipeworks.button_base,
					"splitstacks",
					{
						pipeworks.button_off,
						pipeworks.button_on
					}
				)..pipeworks.button_label
			end
			meta:set_string("formspec", formspec..form_buttons)
		end,
	})

	minetest.register_node("technic_recycler:"..ltier.."_"..machine_name.."_active",{
		description = machine_desc:format(tier),
		tiles = {
			"technic_"..ltier.."_"..machine_name.."_top.png"..tentry,
			"technic_"..ltier.."_"..machine_name.."_bottom.png"..tentry,
			"technic_"..ltier.."_"..machine_name.."_side.png"..tentry,
			"technic_"..ltier.."_"..machine_name.."_side.png"..tentry,
			"technic_"..ltier.."_"..machine_name.."_side.png"..tentry,
			"technic_"..ltier.."_"..machine_name.."_front_active.png"
		},
		paramtype2 = "facedir",
		drop = "technic_recycler:"..ltier.."_"..machine_name,
		groups = active_groups,
		connect_sides = data.connect_sides or connect_default,
		legacy_facedir_simple = true,
		sounds = default.node_sound_wood_defaults(),
		tube = data.tube and tube or nil,
		can_dig = technic.machine_can_dig,
		allow_metadata_inventory_put = technic.machine_inventory_put,
		allow_metadata_inventory_take = technic.machine_inventory_take,
		allow_metadata_inventory_move = technic.machine_inventory_move,
		technic_run = run,
		technic_disabled_machine_name = "technic:"..ltier.."_"..machine_name,
		on_receive_fields = function(pos, formname, fields, sender)
			local node = minetest.get_node(pos)
			if not pipeworks.may_configure(pos, sender) then return end
			fs_helpers.on_receive_fields(pos, fields)
			local meta = minetest.get_meta(pos)
			local form_buttons = ""
			if not string.find(node.name, ":lv_") then
				form_buttons = fs_helpers.cycling_button(
					meta,
					pipeworks.button_base,
					"splitstacks",
					{
						pipeworks.button_off,
						pipeworks.button_on
					}
				)..pipeworks.button_label
			end
			meta:set_string("formspec", formspec..form_buttons)
		end,
	})

	technic.register_machine(tier, "technic_recycler:"..ltier.."_"..machine_name,            technic.receiver)
	technic.register_machine(tier, "technic_recycler:"..ltier.."_"..machine_name.."_active", technic.receiver)

end -- End registration


technic.register_recipe_type("advseparating", {
	description = S("Separating"),
	output_size = 4,
})

function technic.register_advseparating_recipe(data)
	data.time = data.time or 10
	technic.register_recipe("advseparating", data)
end

local recipes = {
	{ "default:cobble",             "technic_recycler:smallpileofcopper",       "technic_recycler:smallpileofiron",  "technic_recycler:tinypileofgold",  "technic_recycler:tinypileofaluminium"    },
}

for _, data in pairs(recipes) do
	technic.register_advseparating_recipe({ input = { data[1] }, output = { data[2], data[3], data[4], data[5] } })
end

function technic.register_cobbleCentrifuge(data)
	data.typename = "advseparating"
	data.machine_name = "advanced_centrifuge"
	data.machine_desc = S("%s Advanced Centrifuge")
	register_base_machine(data)
end

minetest.register_craft({
	output = "technic_recycler:hv_ccentrifuge",
	recipe = {
		{"technic:motor",          "technic:composite_plate",   "technic:motor"},
		{"technic:carbon_plate",   "technic:machine_casing", "technic:copper_plate"      },
		{"pipeworks:one_way_tube", "technic:hv_cable",       "pipeworks:mese_filter"     },
	}
})

technic.register_cobbleCentrifuge({
	tier = "HV",
	demand = { 8000, 7000, 6000 },
	speed = 1,
	upgrade = 1,
	tube = 1,
})

-- Register Items

minetest.register_craftitem("technic_recycler:tinypileofgold", {
	description = S("A Few Miligrams Of Gold"),
	inventory_image = "goldsmol.png",
})
minetest.register_craftitem("technic_recycler:tinypileofaluminium", {
	description = S("A Few Miligrams Of Aluminium"),
	inventory_image = "aluminiumsmol.png",
})

minetest.register_craftitem("technic_recycler:smallpileofcopper", {
	description = S("A Few Grams Of Copper"),
	inventory_image = "coppergram.png",
})
minetest.register_craftitem("technic_recycler:smallpileofiron", {
	description = S("A Few Grams Of Iron"),
	inventory_image = "irongram.png",
})
minetest.register_craftitem("technic_recycler:smallpileofgold", {
	description = S("A Few Grams Of Gold"),
	inventory_image = "goldgram.png",
})
minetest.register_craftitem("technic_recycler:smallpileofaluminium", {
	description = S("A Few Grams Of Aluminium"),
	inventory_image = "aluminiumgram.png",
})

minetest.register_craftitem("technic_recycler:pileofcopper", {
	description = S("Pile Of Copper"),
	inventory_image = "copperpile.png",
})
minetest.register_craftitem("technic_recycler:pileofiron", {
	description = S("Pile Of Iron"),
	inventory_image = "ironpile.png",
})
minetest.register_craftitem("technic_recycler:pileofgold", {
	description = S("Pile Of Gold"),
	inventory_image = "goldpile.png",
})
minetest.register_craftitem("technic_recycler:pileofaluminium", {
	description = S("Pile Of Aluminium"),
	inventory_image = "aluminiumpile.png",
})

minetest.register_craftitem("technic_recycler:aluminium_plate", {
	description = S("Aluminium Plate"),
	inventory_image = "aluminiumplate.png",
})

-- Recipes

local compressorRecipes = {
	{"technic_recycler:tinypileofgold 99", "technic_recycler:smallpileofgold"},
	{"technic_recycler:smallpileofgold 99", "technic_recycler:pileofgold"},
	{"technic_recycler:pileofgold 10", "technic:gold_dust"},
	{"technic_recycler:tinypileofaluminium 99", "technic_recycler:smallpileofaluminium"},
	{"technic_recycler:smallpileofaluminium 99", "technic_recycler:pileofaluminium"},
	{"technic_recycler:pileofaluminium 15", "technic_recycler:aluminium_plate"},
	{"technic_recycler:smallpileofcopper 99", "technic_recycler:pileofcopper"},
	{"technic_recycler:pileofcopper 99", "technic:copper_dust"},
	{"technic_recycler:smallpileofiron 99", "technic_recycler:pileofiron"},
	{"technic_recycler:pileofiron 99", "technic:iron_dust"},
}

for _, data in pairs(recipes) do
	technic.register_compressor_recipe({input = {data[1]}, output = data[2]})
end
