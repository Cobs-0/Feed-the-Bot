extends Node2D

@onready var interact_label: Label = $CanvasLayer/InteractLabel
@onready var player: Node2D = $Player
@export var lantern_item: Item = load("res://items/lantern.tres")
@onready var main_camera: Camera2D = $Camera2D 
@onready var miner_node: Node2D = $Miner 

var near_lantern: bool = false
var near_exit: bool = false
var lantern_collected: bool = false
var blocked_direction: float = 0.0 
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.stream = load("res://assets/SFX/Pickup.wav")
	
	interact_label.text = ""
	if Global.world_state["lantern_collected"]:
		lantern_collected = true
		$Lantern.hide()
		$CanvasModulate.color = Color.BLACK
		$Player/PlayerLight.show()
		
	if Global.world_state.get("entered_cave_after_guard_down", false):
		if miner_node and miner_node.has_method("say"):
			miner_node.say("Ahhhh! Whats that Racket!?", 2.0)
		_shake_camera()
		Global.world_state["entered_cave_after_guard_down"] = false 


func _process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	var direction = Input.get_axis("move_left", "move_right")
	
	if blocked_direction != 0 and sign(direction) == sign(blocked_direction):
		direction = 0
		
	input_vector.x = direction
	
	if input_vector != Vector2.ZERO:
		player.position += input_vector.normalized() * 300 * delta

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if near_lantern and not lantern_collected:
			collect_lantern()
		elif near_exit:
			exit_cave()

func collect_lantern() -> void:
	if player.has_method("collect_item"):
		if player.collect_item(lantern_item):
			lantern_collected = true
			Global.world_state["lantern_collected"] = true
			$Lantern.hide()
			interact_label.text = ""
			
			if $Miner.has_method("say_pickup_line"):
				$Miner.say_pickup_line()
				
			$CanvasModulate.color = Color.BLACK
			$Player/PlayerLight.show()
		else:
			interact_label.text = "My hands are full"

func exit_cave() -> void:
	Global.world_state["world_rotation"] = -1.3
	Global.world_state["cave_exited"] = true
	
	if Global.world_state.get("guard_down", false):
		Global.world_state["exited_cave_after_guard_down"] = true
		
	Global.play_sfx("res://assets/SFX/Pickup.wav")
	get_tree().change_scene_to_file("res://scripts/main.tscn")

func _on_lantern_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_lantern = true
		if not lantern_collected:
			interact_label.text = "Press E to collect Lantern"

func _on_lantern_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_lantern = false
		interact_label.text = ""

func _on_exit_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_exit = true
		interact_label.text = "Press E to exit cave"

func _on_exit_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_exit = false
		interact_label.text = ""

func _on_rightwall_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		blocked_direction = 1.0

func _on_rightwall_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		blocked_direction = 0.0

func _on_leftwall_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		blocked_direction = -1.0

func _on_leftwall_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		blocked_direction = 0.0

func _shake_camera() -> void:
	var original_offset = main_camera.offset
	var shake_strength = 10.0
	var shake_duration = 0.5

	if audio_player:
		audio_player.stream = load("res://assets/SFX/Collaps.wav")
		audio_player.play()

	var tween = create_tween()
	for i in range(50): 
		tween.tween_property(main_camera, "offset", original_offset + Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength)), shake_duration / 5.0)
		tween.tween_property(main_camera, "offset", original_offset, shake_duration / 5.0)
		tween.parallel().tween_callback(func():
			if audio_player: 
				audio_player.pitch_scale = randf_range(0.8, 1.2)
				if not audio_player.playing: audio_player.play()
		)
	
	await tween.finished
	main_camera.offset = original_offset 
	if audio_player:
		audio_player.stop()
