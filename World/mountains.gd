extends Node2D

var interact_label: Label
var player_in_range: bool = false
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.stream = load("res://assets/SFX/Pickup.wav") # Transition sound
	
	interact_label = get_tree().root.find_child("InteractLabel", true, false)
	

func _input(event: InputEvent) -> void:
	if player_in_range:
		if event.is_action_pressed("interact"):
			if Global.world_state.get("mountain_collapsed", false):
				if interact_label:
					interact_label.text = "Cave entrance blocked."
					interact_label.visible = true
					get_tree().create_timer(2.0).timeout.connect(func():
						interact_label.visible = false
					)
			else:
				enter_cave()

func enter_cave() -> void:
	if Global.world_state.get("guard_down", false):
		Global.world_state["entered_cave_after_guard_down"] = true
	
	Global.play_sfx("res://assets/SFX/Pickup.wav")
	get_tree().change_scene_to_file("res://World/cave.tscn")

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = true
		if interact_label:
			if Global.world_state.get("mountain_collapsed", false):
				interact_label.text = "Cave entrance blocked."
			else:
				interact_label.text = "Press E to enter Cave"
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
