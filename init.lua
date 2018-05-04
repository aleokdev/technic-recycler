local S = technic.getter

function technic.register_advseparating_recipe(data)
	data.time = data.time or 10
	technic.register_recipe("advseparating", data)
end

local recipes = {
	{ "minetest:cobblestone 1",             "technic_recycler:smallpileofcopper",       "technic_recycler:smallpileofiron",  "technic_recycler:tinypileofgold",  "technic_recycler:tinypileofaluminium"    },
}

for _, data in pairs(recipes) do
	technic.register_advseparating_recipe({ input = { data[1] }, output = { data[2], data[3], data[4], data[5] } })
end

function technic.register_cobbleCentrifuge(data)
	data.typename = "advseparating"
	data.machine_name = "advanced centrifuge"
	data.machine_desc = S("%s Advanced Centrifuge")
	technic.register_base_machine(data)
end

minetest.register_craft({
	output = "technic:hv_ccentrifuge",
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


