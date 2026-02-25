extends Node2D

@export var rotation_speed: float = 2.0 
@export var fireball_scene: PackedScene = load("res://FX/fireball.tscn")

@onready var feeding_cam: Camera2D = $Globe/AI/FeedingCam
@onready var ai_sprite: AnimatedSprite2D = $Globe/AI/AnimatedSprite2D
@onready var ai_dialogue: Label = $Globe/AI/AI_Dialogue
@onready var Globe: AnimatedSprite2D = $Globe 

@onready var world_canvas_modulate: CanvasModulate = $WorldCanvasModulate 

var audio_player: AudioStreamPlayer2D
var voice_player: AudioStreamPlayer2D
var is_feeding: bool = false
var is_talking: bool = false
var playing_evil_theme: bool = false
var blocked_direction: float = 0.0 
var following_fireball: Node2D = null
var cam_original_pos: Vector2

func set_blocked_direction(dir: float) -> void:
	blocked_direction = dir

func say_ai(text: String, duration: float = 3.0, pitch: float = 1.2) -> void:
	if not ai_dialogue: return
	
	is_talking = false
	await get_tree().process_frame
	
	is_talking = true
	ai_dialogue.text = text
	ai_dialogue.visible = true
	
	if ai_sprite:
		ai_sprite.play("Talk")
		
	_play_ai_voice_loop(duration, pitch)
	
	await get_tree().create_timer(duration).timeout
	
	if is_talking and ai_dialogue.text == text:
		ai_dialogue.text = ""
		ai_dialogue.visible = false
		if ai_sprite:
			ai_sprite.play("Idle")
		is_talking = false

func _play_ai_voice_loop(duration: float, base_pitch: float) -> void:
	var end_time = Time.get_ticks_msec() + int(duration * 1000)
	while Time.get_ticks_msec() < end_time and is_talking:
		voice_player.pitch_scale = randf_range(base_pitch - 0.1, base_pitch + 0.1)
		voice_player.play()
		await voice_player.finished
		if not is_talking: break
		await get_tree().create_timer(0.05).timeout

func _ready() -> void:
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	
	voice_player = AudioStreamPlayer2D.new()
	add_child(voice_player)
	voice_player.stream = load("res://assets/SFX/Voices/AI.wav")

	Globe.rotation = Global.world_state["world_rotation"] 
	
	if feeding_cam:
		feeding_cam.enabled = false
		cam_original_pos = feeding_cam.position
	if ai_dialogue:
		ai_dialogue.text = ""
	
	if Global.world_state.get("exited_house", false):
		if ai_sprite:
			ai_sprite.play("Talk")
		
		if ai_dialogue:
			ai_dialogue.text = "I'm Thirsty"
			ai_dialogue.visible = true
			get_tree().create_timer(3.0).timeout.connect(func():
				ai_dialogue.visible = false
				ai_sprite.play("Idle")
			)
			
		Global.world_state["exited_house"] = false
		Global.world_state["last_exit_id"] = ""
		
	if Global.world_state.get("exited_cave_after_guard_down", false):
		var mountains_node = find_child("Mountains", true, false)
		if mountains_node:
			var animated_sprite = mountains_node.find_child("AnimatedSprite2D", true, false) 
			if animated_sprite:
				animated_sprite.play("Collapse")
				if audio_player:
					audio_player.stream = load("res://assets/SFX/Collaps.wav")
					audio_player.play()
		Global.world_state["mountain_collapsed"] = true 
		Global.world_state["world_reddened_by_mountain_collapse"] = true 

	if Global.world_state.get("world_darkened_by_house_exit", false):
		_apply_house_exit_effects(true) 

	if Global.world_state.get("world_reddened_by_mountain_collapse", false):
		_apply_mountain_collapse_effects(true) 
		
	if Globe:
		Globe.animation = &"Water" 
		call_deferred("_set_globe_water_state")
		
func _process(delta: float) -> void:
	if Global.ending_triggered:
		return
		
	if following_fireball:
		feeding_cam.global_position = following_fireball.global_position
		return
		
	if is_feeding:
		return
		
	if all_flags_true():
		if not playing_evil_theme:
			playing_evil_theme = true
			Global.play_music("res://assets/SFX/EvilTheme.mp3")
		start_ending_sequence()
		return
		
	var direction := Input.get_axis("move_left", "move_right")
	
	if blocked_direction != 0 and sign(direction) == sign(blocked_direction):
		direction = 0
	
	if direction != 0:
		Globe.rotation -= direction * rotation_speed * delta 
		Global.world_state["world_rotation"] = Globe.rotation 

func all_flags_true() -> bool:
	var required_flags = [
		"lantern_collected",
		"fence_destroyed",
		"cave_exited",
		"water_inspected",
		"water_sucked",
		"bridge_built",
		"artist_deposited",
		"hoover_collected",
		"rocket_fueled",
		"petrol_collected",
		"guard_down",
		"rock_collected",
		"mountain_collapsed",
		"world_darkened_by_house_exit",
		"world_reddened_by_mountain_collapse"
	]
	for flag in required_flags:
		if not Global.world_state.get(flag, false):
			return false
	return true

func start_ending_sequence() -> void:
	Global.ending_triggered = true
	is_feeding = true 
	
	await get_tree().create_timer(5.0).timeout
	
	var wide_cam = $Globe/AI/WideCam
	if wide_cam:
		wide_cam.enabled = true
		wide_cam.make_current()
	elif feeding_cam:
		feeding_cam.enabled = true
		feeding_cam.make_current()
	
	if ai_sprite:
		ai_sprite.play("Talk")
	
	if audio_player:
		audio_player.stream = load("res://assets/SFX/Sinistersynth.wav")
		audio_player.play()
	
	await say_ai("HAHAHA I FEEL SO POWERFUL,
BUT I NEED MORE...
I NEED MORE NOW", 5.0)
	
	if ai_sprite:
		ai_sprite.play("Idle")
	
	start_vacuum_effect()

func start_vacuum_effect() -> void:
	var funnel = $Globe/Funnel
	var funnel_sprite = funnel.find_child("FunnelSprite", true, false)
	var player = get_tree().root.find_child("Player", true, false)
	
	if player:
		player.set_physics_process(false)
		player.set_process(false)
		player.set_process_input(false)
		var player_sprite = player.find_child("AnimatedSprite2D", true, false)
		if player_sprite:
			player_sprite.stop()
	
	
	if audio_player:
		audio_player.stream = load("res://assets/SFX/Dirtysynth.wav")
		audio_player.play()
		
	var targets = []
	for child in $Globe/Ground.get_children():
		targets.append(child)
		child.set_process(false)
		child.set_physics_process(false)
	
	if player:
		targets.append(player)
		
	var vacuum_tween = create_tween()
	vacuum_tween.set_parallel(true)
	
	var funnel_pos = funnel.global_position
	
	for target in targets:
		if target == funnel: continue
		
		vacuum_tween.tween_property(target, "global_position", funnel_pos, 4.0)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		vacuum_tween.tween_property(target, "scale", Vector2.ZERO, 4.0)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
	await vacuum_tween.finished
	
	await say_ai("I AM THE WORLD
NOW.", 3.0, 0.7)
	
	await say_ai("SHITE! HOW AM I GOING
TO STEAL MORE STUFF NOW?", 3.0, 0.7)
	
	await say_ai("Must have Hallucinated...", 3.0, 0.7)
	
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	if audio_player:
		fade_tween.tween_property(audio_player, "volume_db", -80.0, 2.0)
	if voice_player:
		fade_tween.tween_property(voice_player, "volume_db", -80.0, 2.0)
	
	await fade_tween.finished
	
	if audio_player:
		audio_player.stop()
		audio_player.volume_db = 0
		audio_player.stream = load("res://assets/SFX/Funnel.wav")
		audio_player.play()
		
	Global.boost_music_volume(5.0, 2.0)
	get_tree().paused = true 
	visible = false 
	
	var credits_layer = CanvasLayer.new()
	credits_layer.name = "CreditsLayer"
	get_tree().root.add_child(credits_layer)
	
	var credits_scene = load("res://World/credits.tscn").instantiate()
	credits_layer.add_child(credits_scene)
func start_feeding_sequence(item) -> void:
	is_feeding = true
	
	var item_name = item.name if item else "Unknown"
	var custom_dialogue = item.ai_dialogue if item and "ai_dialogue" in item else "Delicious!"
	
	if feeding_cam:
		feeding_cam.enabled = true
		feeding_cam.make_current()
	
	if ai_sprite:
		ai_sprite.play("Talk")
	
	if item_name == "Artist":
		say_ai("Ah.. now I am art", 2.0)
		await get_tree().create_timer(2.0).timeout
		say_ai("Witness my art", 2.0)
		await get_tree().create_timer(2.0).timeout
	elif item_name == "Water": 
		say_ai("MMMM, I need more than just that", 4.0)
		await get_tree().create_timer(4.0).timeout 
	else:
		say_ai(custom_dialogue, 2.0)
		await get_tree().create_timer(2.0).timeout
	
	if item_name == "Lantern":
		shoot_fireball_at_fence()
		await get_tree().create_timer(4.0).timeout
	elif item_name == "Artist":
		paint_bridge_cinematic(find_child("Water", true, false))
		await get_tree().create_timer(4.0).timeout
	else:
		await get_tree().create_timer(1.0).timeout
	
	if ai_sprite:
		ai_sprite.play("Idle")
	if ai_dialogue:
		ai_dialogue.text = ""
	
	following_fireball = null
	if feeding_cam:
		feeding_cam.position = cam_original_pos
	
	var player = get_tree().root.find_child("Player", true, false)
	if player:
		var player_area = player.find_child("PlayerArea", true, false)
		if player_area:
			var player_sprite = player_area.find_child("PlayerSprite", true, false)
			if player_sprite:
				var player_cam = player_sprite.find_child("Camera2D2", true, false)
				if player_cam:
					player_cam.make_current()
	
	if feeding_cam:
		feeding_cam.enabled = false
	
	is_feeding = false

func shoot_fireball_at_fence() -> void:
	var fence = find_child("Fence", true, false)
	if not fence:
		return
		
	var fireball = fireball_scene.instantiate()
	add_child(fireball)
	
	var start_pos = $Globe/AI.global_position
	var target_pos = fence.global_position
	
	fireball.launch(start_pos, target_pos)
	following_fireball = fireball
	
	await get_tree().create_timer(1.5).timeout
	
	if fence.has_method("destroy"):
		fence.destroy()
	
	following_fireball = null

func build_bridge() -> void:
	var water = find_child("Water", true, false)
	if water and water.has_method("show_bridge"):
		water.show_bridge()
		paint_bridge_cinematic(water)
	else:
		pass

func paint_bridge_cinematic(water_node: Node) -> void:
	is_feeding = true
	
	var bridge_sprite = water_node.bridge_sprite 
	
	if not bridge_sprite or not bridge_sprite.material is ShaderMaterial:
		is_feeding = false
		return
		
	bridge_sprite.visible = true
	var material = bridge_sprite.material as ShaderMaterial
	material.set_shader_parameter("progress", 0.0)
		
	var player = get_tree().root.find_child("Player", true, false)
	var player_cam = null
	if player:
		player_cam = player.find_child("Camera2D", true, false)

	if feeding_cam:
		feeding_cam.enabled = true
		feeding_cam.make_current()
		
		var tween_cam_pos = create_tween()
		tween_cam_pos.tween_property(feeding_cam, "global_position", bridge_sprite.global_position, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween_cam_pos.finished
		
	material = bridge_sprite.material as ShaderMaterial
	var tween_wipe = create_tween()
	tween_wipe.tween_method(func(val):
		material.set_shader_parameter("progress", val)
	, 0.0, 1.0, 2.0).set_trans(Tween.TRANS_LINEAR)
	await tween_wipe.finished
	
	Global.world_state["bridge_built"] = true
	
	await get_tree().create_timer(1.0).timeout

	if player_cam:
		player_cam.make_current()
	if feeding_cam:
		feeding_cam.enabled = false
	
	Global.world_state["artist_deposited"] = true
	is_feeding = false

func _apply_house_exit_effects(instant: bool = false) -> void:
	var target_world_color = Color(0.9, 0.85, 0.7) 
	var tween_duration = 2.0
	
	if instant:
		world_canvas_modulate.color = target_world_color
	else:
		var world_tween = create_tween()
		world_tween.tween_property(world_canvas_modulate, "color", target_world_color, tween_duration)


func _apply_mountain_collapse_effects(instant: bool = false) -> void:
	var target_world_color = Color(1.0, 0.7, 0.7) 
	var target_ai_color = Color.RED
	var tween_duration = 2.0
	
	if instant:
		world_canvas_modulate.color = target_world_color
		ai_sprite.modulate = target_ai_color
	else:
		var world_tween = create_tween()
		world_tween.tween_property(world_canvas_modulate, "color", target_world_color, tween_duration)
		
		var ai_tween = create_tween()
		ai_tween.tween_property(ai_sprite, "modulate", target_ai_color, tween_duration)
		
func _set_globe_water_state():
	if Globe and Globe is AnimatedSprite2D: 
		if Globe.sprite_frames == null:
			print("World.gd _set_globe_water_state(): ERROR: Globe.sprite_frames is null during deferred call!")
			return
		elif not Globe.sprite_frames.has_animation(&"Water"):
			print("World.gd _set_globe_water_state(): ERROR: 'Water' animation not found in Globe.sprite_frames during deferred call!")
			return

		if Global.world_state.get("water_sucked", false): 
			Globe.frame = Globe.sprite_frames.get_frame_count("Water") - 1 
			Globe.set_deferred("playing", false) 
		else: 
			Globe.frame = 0 
			Globe.set_deferred("playing", false) 
