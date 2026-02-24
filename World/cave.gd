extends Node2D

@onready var interact_label: Label = $CanvasLayer/InteractLabel
@onready var player: Node2D = $Player
@export var lantern_item: Item = load("res://items/lantern.tres")
@onready var main_camera: Camera2D = $Camera2D # Added for camera shake
@onready var miner_node: Node2D = $Miner # Added for miner dialogue

var near_lantern: bool = false
var near_exit: bool = false
var lantern_collected: bool = false
var blocked_direction: float = 0.0 # 1: right, -1: left

func _ready() -> void:
	interact_label.text = ""
	if Global.world_state["lantern_collected"]:
		lantern_collected = true
		$Lantern.hide()
		$CanvasModulate.color = Color.BLACK
		$Player/PlayerLight.show()
		
	# New logic for guard interaction
	if Global.world_state.get("entered_cave_after_guard_down", false):
		_shake_camera()
		if miner_node and miner_node.has_node("DialogueLabel"):
			var miner_dialogue_label = miner_node.get_node("DialogueLabel")
			if miner_dialogue_label:
				miner_dialogue_label.text = "Ahhhh! Whats that Racket!?"
				await get_tree().create_timer(2.0).timeout # Shorter duration for exclamation
				miner_dialogue_label.text = ""
		Global.world_state["entered_cave_after_guard_down"] = false # Reset the flag


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
			
			# Miner reaction
			if $Miner.has_method("say_pickup_line"):
				$Miner.say_pickup_line()
				
			# Darkness effect
			$CanvasModulate.color = Color.BLACK
			$Player/PlayerLight.show()
		else:
			interact_label.text = "My hands are full"

func exit_cave() -> void:
	Global.world_state["world_rotation"] = -1.3
	Global.world_state["cave_exited"] = true
	
	# New logic for guard interaction on exit
	if Global.world_state.get("guard_down", false):
		Global.world_state["exited_cave_after_guard_down"] = true
		
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

	var tween = create_tween()
	for i in range(50): # Shake multiple times
		tween.tween_property(main_camera, "offset", original_offset + Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength)), shake_duration / 5.0)
		tween.tween_property(main_camera, "offset", original_offset, shake_duration / 5.0)
	await tween.finished
	main_camera.offset = original_offset # Ensure it ends at original position
