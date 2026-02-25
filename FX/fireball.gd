extends Node2D

var target_position: Vector2
var speed: float = 600.0
var active: bool = false
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.stream = load("res://assets/SFX/Fireball.wav")

func _process(delta: float) -> void:
	if not active:
		return
		
	var direction = (target_position - global_position).normalized()
	global_position += direction * speed * delta
	
	if global_position.distance_to(target_position) < 20.0:
		active = false
		queue_free()

func launch(start_pos: Vector2, target_pos: Vector2) -> void:
	global_position = start_pos
	target_position = target_pos
	active = true
	if audio_player:
		audio_player.play()
