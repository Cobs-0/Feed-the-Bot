extends Node

var current_item = null:
	set(value):
		if value != current_item:
			print("Global.current_item changed from ", current_item, " to ", value)
			if value:
				print("New item name: ", value.name)
			current_item = value
	get:
		return current_item

var world_state = {
	"chopped_trees": [],
	"lantern_collected": false,
	"world_rotation": 0.0,
	"fence_destroyed": false,
	"cave_exited": false,
	"water_inspected": false,
	"water_sucked": false,
	"bridge_built": false,
	"artist_deposited": false,
	"hoover_filled_with_water": false,
	"hoover_collected": false,
	"rocket_fueled": false,
	"petrol_collected": false,
	"guard_down": false,
	"rock_collected": false,
	"mountain_collapsed": false,
	"world_darkened_by_house_exit": false,
	"world_reddened_by_mountain_collapse": false
}
