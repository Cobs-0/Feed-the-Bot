extends Node2D

@export var rotation_speed: float = 2.0 
@export var fireball_scene: PackedScene = load("res://FX/fireball.tscn")

@onready var feeding_cam: Camera2D = $Globe/AI/FeedingCam
@onready var ai_sprite: AnimatedSprite2D = $Globe/AI/AnimatedSprite2D
@onready var ai_dialogue: Label = $Globe/AI/AI_Dialogue
@onready var Globe: AnimatedSprite2D = $Globe # Added reference to the Globe node

@onready var world_canvas_modulate: CanvasModulate = $WorldCanvasModulate # Added for world darkening

var is_feeding: bool = false
var blocked_direction: float = 0.0 # 1: right, -1: left
var following_fireball: Node2D = null
var cam_original_pos: Vector2

func set_blocked_direction(dir: float) -> void:
	blocked_direction = dir

func _ready() -> void:


	Globe.rotation = Global.world_state["world_rotation"] # Applied rotation to Globe
	
	if feeding_cam:
		feeding_cam.enabled = false
		cam_original_pos = feeding_cam.position
	if ai_dialogue:
		ai_dialogue.text = ""
	
	if Global.world_state.has("exited_house") and Global.world_state["exited_house"] == true:
		if ai_dialogue and ai_sprite:
			ai_dialogue.text = "I'm Thirsty"
			ai_dialogue.visible = true
			ai_sprite.play("Talk")
			
			get_tree().create_timer(3.0).timeout.connect(func():
				ai_dialogue.visible = false
				ai_sprite.play("Idle")
			)
			
		Global.world_state["exited_house"] = false
		Global.world_state["last_exit_id"] = ""
		
	# New logic for mountain collapse after exiting cave with guard down
	if Global.world_state.get("exited_cave_after_guard_down", false):
		var mountains_node = find_child("Mountains", true, false)
		if mountains_node:
			var animated_sprite = mountains_node.find_child("AnimatedSprite2D", true, false) # Mountains/Area2D/AnimatedSprite2D
			if animated_sprite:
				animated_sprite.play("Collapse")
				# Optionally wait for animation to finish if needed
				# await animated_sprite.animation_finished
		Global.world_state["mountain_collapsed"] = true # Persist the collapsed state
		Global.world_state["world_reddened_by_mountain_collapse"] = true # Set flag for reddening world
		# Global.world_state["exited_cave_after_guard_down"] = false # Removed: this flag should not reset here

	# New logic for world darkening after exiting house
	if Global.world_state.get("world_darkened_by_house_exit", false):
		_apply_house_exit_effects(true) # Apply instantly on scene load if flag is set

	# New logic for world reddening after mountain collapse
	if Global.world_state.get("world_reddened_by_mountain_collapse", false):
		_apply_mountain_collapse_effects(true) # Apply instantly on scene load if flag is set
		
	if Globe:
		Globe.animation = &"Water" # Ensure animation is set
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
		start_ending_sequence()
		return
		
	var direction := Input.get_axis("move_left", "move_right")
	
	if blocked_direction != 0 and sign(direction) == sign(blocked_direction):
		direction = 0
	
	if direction != 0:
		Globe.rotation -= direction * rotation_speed * delta # Applied rotation to Globe
		Global.world_state["world_rotation"] = Globe.rotation # Store Globe's rotation

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
	is_feeding = true # Block other interactions
	
	# Wait 5 seconds
	await get_tree().create_timer(5.0).timeout
	
	# Switch to WideCam
	var wide_cam = $Globe/AI/WideCam
	if wide_cam:
		wide_cam.enabled = true
		wide_cam.make_current()
	elif feeding_cam:
		feeding_cam.enabled = true
		feeding_cam.make_current()
	
	if ai_sprite:
		ai_sprite.play("Talk")
	
	if ai_dialogue:
		ai_dialogue.text = "HAHAHA I FEEL SO POWERFUL,
BUT I NEED MORE...
I NEED MORE NOW"
		ai_dialogue.visible = true
	
	await get_tree().create_timer(5.0).timeout
	
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
		# Try to stop player animations if any
		var player_sprite = player.find_child("AnimatedSprite2D", true, false)
		if player_sprite:
			player_sprite.stop()
	
	# Funnel no longer spins
	
	# Get all targets
	var targets = []
	# Suck up everything on the ground
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
		
		# Move towards funnel and scale down
		vacuum_tween.tween_property(target, "global_position", funnel_pos, 4.0)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		vacuum_tween.tween_property(target, "scale", Vector2.ZERO, 4.0)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
	await vacuum_tween.finished
	
	if ai_dialogue:
		ai_dialogue.text = "I AM THE WORLD
NOW."
		ai_dialogue.visible = true
		
	await get_tree().create_timer(3.0).timeout
	
	# Add new AI dialogue
	if ai_dialogue:
		ai_dialogue.text = "Shite, How am I going to steal more stuff now?"
		ai_dialogue.visible = true
	await get_tree().create_timer(3.0).timeout
	
	if ai_dialogue:
		ai_dialogue.text = "Must have Hallucinated..."
		ai_dialogue.visible = true
	await get_tree().create_timer(3.0).timeout
		
	get_tree().paused = true # Pause the game
	visible = false # Hide the World node (which contains the Globe/planet)
	
	# Instantiate credits scene
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
	
	if ai_dialogue:
		ai_dialogue.text = "Yummy " + item_name + "!"
		await get_tree().create_timer(1.0).timeout 

		if item_name == "Artist":
			ai_dialogue.text = "Ah.. now I am art"
			ai_dialogue.visible = true
			await get_tree().create_timer(2.0).timeout
			ai_dialogue.text = "Witness my art"
			await get_tree().create_timer(2.0).timeout
		elif item_name == "Water": # Specific dialogue for water
			ai_dialogue.text = "MMMM, I need more than just that"
			ai_dialogue.visible = true
			await get_tree().create_timer(4.0).timeout # Keep dialogue for a short time
		else:
			ai_dialogue.text = custom_dialogue
			ai_dialogue.visible = true
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
	var target_world_color = Color(0.9, 0.85, 0.7) # Less saturated, yellowish
	var tween_duration = 2.0
	
	if instant:
		world_canvas_modulate.color = target_world_color
	else:
		var world_tween = create_tween()
		world_tween.tween_property(world_canvas_modulate, "color", target_world_color, tween_duration)


func _apply_mountain_collapse_effects(instant: bool = false) -> void:
	var target_world_color = Color(1.0, 0.7, 0.7) # Reddish tint, slightly desaturated
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
	if Globe and Globe is AnimatedSprite2D: # Check if Globe is still valid and correct type in deferred call
		if Globe.sprite_frames == null:
			print("World.gd _set_globe_water_state(): ERROR: Globe.sprite_frames is null during deferred call!")
			return
		elif not Globe.sprite_frames.has_animation(&"Water"):
			print("World.gd _set_globe_water_state(): ERROR: 'Water' animation not found in Globe.sprite_frames during deferred call!")
			return

		if Global.world_state.get("water_sucked", false): # If water has been sucked (implies NO water visually, so show last frame)
			Globe.frame = Globe.sprite_frames.get_frame_count("Water") - 1 # Set to last frame (no water)
			Globe.set_deferred("playing", false) # Hold last frame
		else: # If water has NOT been sucked (implies WATER PRESENT visually, so show first frame)
			Globe.frame = 0 # Set to first frame (water present)
			Globe.set_deferred("playing", false) # Hold first frame
