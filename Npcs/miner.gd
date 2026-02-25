extends Node2D

@onready var dialogue_label: Label = $DialogueLabel
var voice_player: AudioStreamPlayer2D
var mine_sfx_player: AudioStreamPlayer2D
var is_talking: bool = false

func _ready() -> void:
	voice_player = AudioStreamPlayer2D.new()
	add_child(voice_player)
	voice_player.stream = load("res://assets/SFX/Voices/Miner.wav")
	
	mine_sfx_player = AudioStreamPlayer2D.new()
	add_child(mine_sfx_player)
	mine_sfx_player.stream = load("res://assets/SFX/Mine.wav")
	_start_mining_sounds()
	
	if dialogue_label:
		dialogue_label.text = ""

func _start_mining_sounds() -> void:
	while is_inside_tree():
		if not is_talking:
			await get_tree().create_timer(randf_range(0.5, 1.5)).timeout
			if is_inside_tree() and not is_talking:
				mine_sfx_player.pitch_scale = randf_range(1.1, 1.3)
				mine_sfx_player.play()
		else:
			await get_tree().create_timer(1.0).timeout

func say(text: String, duration: float = 3.0) -> void:
	if not dialogue_label: return
	
	is_talking = false
	await get_tree().process_frame
	
	is_talking = true
	dialogue_label.text = text
	_play_voice_loop(duration)
	
	await get_tree().create_timer(duration).timeout
	
	dialogue_label.text = ""
	is_talking = false

func _play_voice_loop(duration: float) -> void:
	var end_time = Time.get_ticks_msec() + int(duration * 1000)
	while Time.get_ticks_msec() < end_time and is_talking:
		voice_player.pitch_scale = randf_range(0.85, 1.15)
		voice_player.play()
		await voice_player.finished
		if not is_talking: break
		await get_tree().create_timer(0.05).timeout

func say_pickup_line() -> void:
	await say("Oh why'd you have to do that Mr...")

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		if dialogue_label and not Global.world_state["lantern_collected"]:
			say("If you pick up that lantern there's gonna be trouble!")

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		if dialogue_label:
			dialogue_label.text = ""
