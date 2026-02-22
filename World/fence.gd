extends Node2D

var interact_label: Label
var player_in_range: bool = false

func _ready() -> void:
	interact_label = get_tree().root.find_child("InteractLabel", true, false)
	
	if Global.world_state["fence_destroyed"]:
		queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = true
		
		if not Global.world_state["fence_destroyed"]:
			var world = get_tree().root.find_child("World", true, false)
			if world and world.has_method("set_blocked_direction"):
				var move_dir = Input.get_axis("move_left", "move_right")
				if move_dir == 0: move_dir = -1.0 
				world.set_blocked_direction(sign(move_dir))

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = false
		
		var world = get_tree().root.find_child("World", true, false)
		if world and world.has_method("set_blocked_direction"):
			world.set_blocked_direction(0.0)

func destroy() -> void:
	Global.world_state["fence_destroyed"] = true
	queue_free()
