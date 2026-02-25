extends Node2D

@onready var artist_sprite: AnimatedSprite2D = $Area2D/ArtistSprite
@onready var dialogue_label: Label = $DialogueLabel

@export var artist_item: Item = load("res://items/artist_item.tres")

var player_in_range: bool = false
var is_talking: bool = false
var voice_player: AudioStreamPlayer2D

func _ready() -> void:
	voice_player = AudioStreamPlayer2D.new()
	add_child(voice_player)
	voice_player.stream = load("res://assets/SFX/Voices/Artist.wav")
	
	if not Global.world_state["cave_exited"] or Global.world_state["artist_deposited"]:
		hide()
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
		set_process_input(false)
	else:
		show()
		$Area2D/CollisionShape2D.set_deferred("disabled", false)
		set_process_input(true)
	
	if dialogue_label:
		dialogue_label.text = ""

func _input(event: InputEvent) -> void:
	if not visible: return
	
	if event.is_action_pressed("interact") and player_in_range:
		if Global.world_state["water_inspected"]:
			pick_up()
		elif not is_talking:
			talk()

func pick_up() -> void:
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("collect_item"):
		if player.collect_item(artist_item):
			queue_free()
		else:
			var label = get_tree().current_scene.find_child("InteractLabel", true, false)
			if label:
				label.text = "My hands are full"

func talk() -> void:
	is_talking = true
	artist_sprite.play("Talk")
	dialogue_label.text = "What happened to the trees?, I loved those trees since I was a child!"
	
	_play_voice_loop(3.0)
	await get_tree().create_timer(3.0).timeout
	
	artist_sprite.play("Idle")
	dialogue_label.text = ""
	is_talking = false

func _play_voice_loop(duration: float) -> void:
	var end_time = Time.get_ticks_msec() + int(duration * 1000)
	while Time.get_ticks_msec() < end_time and is_talking:
		voice_player.pitch_scale = randf_range(0.9, 1.1)
		voice_player.play()
		await voice_player.finished
		if not is_talking: break
		await get_tree().create_timer(0.05).timeout

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = true
		var label = get_tree().current_scene.find_child("InteractLabel", true, false)
		if label:
			label.text = "Press E to Talk"
			label.visible = true

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = false
		var label = get_tree().current_scene.find_child("InteractLabel", true, false)
		if label:
			label.text = ""
			label.visible = false
