extends Node2D

@onready var world_node: Node2D = $World
@onready var player_node: Node2D = $Player 
@onready var ai_dialogue_label: Label = $World/Globe/AI/AI_Dialogue 
@onready var globe_node: AnimatedSprite2D = $World/Globe 

var voice_player: AudioStreamPlayer2D
var is_talking: bool = false

func _ready() -> void:
	voice_player = AudioStreamPlayer2D.new()
	add_child(voice_player)
	voice_player.stream = load("res://assets/SFX/Voices/AI.wav")
	
	if Global.world_state.has("exited_house") and Global.world_state["exited_house"] == true:
		
		set_ai_dialogue("Thirsty")
		
		Global.world_state["exited_house"] = false
		Global.world_state["last_exit_id"] = ""
		
		await get_tree().create_timer(0.1).timeout
		
		if world_node.has_method("set_blocked_direction"):
			world_node.set_blocked_direction(0.0)
	
	var player_area = player_node.find_child("PlayerArea", true, false)
	if player_area:
		var player_sprite = player_area.find_child("PlayerSprite", true, false)
		if player_sprite:
			var player_cam = player_sprite.find_child("Camera2D2", true, false)
			if player_cam:
				player_cam.make_current()

func set_ai_dialogue(text: String) -> void:
	if ai_dialogue_label:
		is_talking = false # Stop previous voice
		await get_tree().process_frame # Let loop finish
		
		ai_dialogue_label.text = text
		ai_dialogue_label.visible = true
		is_talking = true
		_play_voice_loop(3.0)
		
		get_tree().create_timer(3.0).timeout.connect(func():
			ai_dialogue_label.visible = false
			is_talking = false
		)

func _play_voice_loop(duration: float) -> void:
	var end_time = Time.get_ticks_msec() + int(duration * 1000)
	while Time.get_ticks_msec() < end_time and is_talking:
		voice_player.pitch_scale = randf_range(1.1, 1.3) # Higher pitch for AI
		voice_player.play()
		await voice_player.finished
		if not is_talking: break
		await get_tree().create_timer(0.05).timeout
