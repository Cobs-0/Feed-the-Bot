extends Node

var _current_item = null:
	set(value):
		if value != _current_item:
			print("Global.current_item changed from ", _current_item, " to ", value)
			if value:
				print("New item name: ", value.name)
			_current_item = value
	get:
		return _current_item

var world_state = {
	"chopped_trees": [],
	"lantern_collected": false,
	"world_rotation": 0.0,
	"fence_destroyed": false,
	"cave_exited": false,
	"water_inspected": false,
	"bridge_built": false,
	"artist_deposited": false,
	"hoover_filled_with_water": false,
	"hoover_collected": false
}
