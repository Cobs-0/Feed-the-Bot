extends Node2D

var interact_label: Label
var player_in_range: bool = false

func _ready() -> void:
	interact_label = get_tree().root.find_child("InteractLabel", true, false)

func _input(event: InputEvent) -> void:
	if player_in_range:
		if event.is_action_pressed("interact"):
			enter_cave()

func enter_cave() -> void:
	get_tree().change_scene_to_file("res://World/Room/Room.tscn")

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = true
		if interact_label:
			interact_label.text = "Press E to enter House"
			interact_label.visible = true
		
		var world = get_tree().root.find_child("World", true, false)
		if world and world.has_method("set_blocked_direction"):
			var move_dir = Input.get_axis("move_left", "move_right")
			if move_dir == 0: move_dir = 1.0 
			world.set_blocked_direction(sign(move_dir))

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = false
		if interact_label:
			interact_label.text = ""
			interact_label.visible = false
		
		var world = get_tree().root.find_child("World", true, false)
		if world and world.has_method("set_blocked_direction"):
			world.set_blocked_direction(0.0)
