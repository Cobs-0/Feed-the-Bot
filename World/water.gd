extends Node2D

var player_in_range: bool = false
@onready var area_2d: Area2D = $Area2D
@onready var water_collision_shape: CollisionShape2D = $Area2D/CollisionShape2D # New onready var
@onready var bridge_sprite_onready: Sprite2D = $Area2D/BridgeSprite
@onready var water_suck_animation: AnimatedSprite2D = find_parent("World").get_node("Globe")

@onready var ai_animated_sprite: AnimatedSprite2D = find_parent("World").get_node("Globe/AI/AnimatedSprite2D")
@onready var ai_dialogue_label: Label = find_parent("World").get_node("Globe/AI/AI_Dialogue")
@onready var interact_label: Label = get_tree().root.find_child("InteractLabel", true, false)
@onready var movable_player: Node2D = get_tree().root.find_child("Player", true, false) # Get reference to MovablePlayer

@export var bridge_sprite: Sprite2D 
var wipe_shader = preload("res://assets/shaders/wipe.gdshader")


func _ready() -> void:
	# If water has already been sucked up, disable its interaction
	if Global.world_state.get("water_sucked", false):
		if area_2d:
			area_2d.monitorable = false
			area_2d.input_pickable = false
			water_collision_shape.disabled = true # Disable collision
		# Do NOT hide area_2d
		
	if bridge_sprite_onready:
		bridge_sprite = bridge_sprite_onready
	else:
		bridge_sprite = find_child("BridgeSprite", true, false)

	if bridge_sprite:
		var material = ShaderMaterial.new()
		material.shader = wipe_shader
		bridge_sprite.material = material
		if Global.world_state["bridge_built"]:
			material.set_shader_parameter("progress", 1.0)
			bridge_sprite.visible = true
		else:
			material.set_shader_parameter("progress", 0.0)
	
	if area_2d:
		if not area_2d.area_entered.is_connected(_on_area_entered):
			area_2d.area_entered.connect(_on_area_entered)
		if not area_2d.area_exited.is_connected(_on_area_exited):
			area_2d.area_exited.connect(_on_area_exited)
	else:
		area_2d = get_node_or_null("Area2D")
		if area_2d:
			if not area_2d.area_entered.is_connected(_on_area_entered):
				area_2d.area_entered.connect(_on_area_entered)
			if not area_2d.area_exited.is_connected(_on_area_exited):
				area_2d.area_exited.connect(_on_area_exited)

func show_bridge() -> void:
	if not bridge_sprite:
		bridge_sprite = find_child("BridgeSprite", true, false)
	if bridge_sprite and bridge_sprite.material is ShaderMaterial:
		(bridge_sprite.material as ShaderMaterial).set_shader_parameter("progress", 0.0)
		bridge_sprite.visible = true

func _input(event: InputEvent) -> void:
	print("Water _input running!") # DEBUG
	print("player_in_range: ", player_in_range) # DEBUG
	print("Event action pressed (interact): ", event.is_action_pressed("interact")) # DEBUG
	
	if not player_in_range: return
	
	if event.is_action_pressed("interact"):
		print("--- Interact Pressed ---") # DEBUG
		
		# Removed: if Global.world_state["bridge_built"]: return
		
		if Global.current_item:
			print("Current Item Name: ", Global.current_item.name)
			print("Is current item Hoover? ", Global.current_item.name == "Hoover") # DEBUG
		else:
			print("Current Item: None")
		print("Hoover filled with water state: ", Global.world_state.get("hoover_filled_with_water", false))
		
		var has_hoover = Global.current_item and Global.current_item.name == "Hoover"
		var hoover_is_filled = Global.world_state.get("hoover_filled_with_water", false)
		
		print("has_hoover: ", has_hoover) # DEBUG
		print("hoover_is_filled: ", hoover_is_filled) # DEBUG
		
		if has_hoover and not hoover_is_filled:
			print("Entering Hoover interaction block - Condition passed!") # DEBUG
			# AI Dialogue: "Give me that!"
			if ai_dialogue_label and ai_animated_sprite:
				ai_dialogue_label.text = "Give me that!"
				ai_dialogue_label.visible = true
				ai_animated_sprite.play("Talk")
			
			# Play WaterSucker animation
			if water_suck_animation:
				water_suck_animation.play("Water")
				water_suck_animation.animation_finished.connect(_on_water_suck_animation_finished)
				if interact_label:
					interact_label.visible = false # Hide label during animation
		elif not has_hoover: # No Hoover, or wrong item
			print("Entering Inspect water block - No Hoover detected.") # DEBUG
			inspect_water()
		elif has_hoover and hoover_is_filled: # Hoover is filled
			print("Entering Hoover full block - Hoover is already full.") # DEBUG
			if interact_label:
				interact_label.text = "The Hoover is already full!"
				interact_label.visible = true
				get_tree().create_timer(2.0).timeout.connect(func():
					interact_label.visible = false
				)


func inspect_water() -> void:
	# This function is no longer called directly from _input, but is kept for potential future use or from bridge logic
	if Global.world_state["water_inspected"]:
		return

	var world_node = get_tree().current_scene
	var ai_cam = world_node.find_child("FeedingCam", true, false)
	var player_cam = null
	
	var player = world_node.find_child("Player", true, false)
	if player:
		player_cam = player.find_child("Camera2D", true, false)

	if ai_cam:
		ai_cam.enabled = true
		ai_cam.make_current()

	var interact_label_local = world_node.find_child("InteractLabel", true, false)
	if interact_label_local:
		interact_label_local.text = "I can't get past."
		interact_label_local.visible = true
		
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(func():
			if interact_label_local.text == "I can't get past.":
				interact_label_local.visible = false
		)

	Global.world_state["water_inspected"] = true
	
	var ai_dialogue_local = world_node.find_child("AI_Dialogue", true, false)
	var ai_sprite_local = null
	
	var ai_node = world_node.find_child("AI", true, false)
	if ai_node:
		ai_sprite_local = ai_node.find_child("AnimatedSprite2D")
		
	if ai_dialogue_local and ai_sprite_local:
		ai_sprite_local.play("Talk")
		ai_dialogue_local.text = "If only I could paint."
		ai_dialogue_local.visible = true
		
		await get_tree().create_timer(4.0).timeout
		
		ai_dialogue_local.text = ""
		ai_dialogue_local.visible = false
		ai_sprite_local.play("Idle")
	
	if player_cam:
		player_cam.make_current()
	if ai_cam:
		ai_cam.enabled = false

func _on_area_entered(area: Area2D) -> void:
	print("Water Area Entered! Area: ", area.name) # DEBUG
	if area.name == "PlayerArea":
		player_in_range = true
		print("player_in_range after entered: ", player_in_range) # DEBUG
		
		# Handle Interact Label visibility based on Hoover and Bridge state
		if interact_label:
			var has_hoover = Global.current_item and Global.current_item.name == "Hoover"
			var hoover_is_filled = Global.world_state.get("hoover_filled_with_water", false)

			# Show "Suck up Water" prompt only if Hoover is equipped AND not filled
			if has_hoover and not hoover_is_filled:
				interact_label.text = "Press E to Suck up the Water"
				interact_label.visible = true
			else: # Hide prompt for Hoover interaction if no Hoover, or Hoover is filled
				interact_label.visible = false

		# Handle blocking based on Bridge state
		var world = find_parent("World")
		if world and world.has_method("set_blocked_direction"):
			if Global.world_state["bridge_built"]: # If bridge is built, do not block movement
				world.set_blocked_direction(0.0) # Ensure it's not blocked
			else: # If bridge is not built, block movement
				var move_dir = Input.get_axis("move_left", "move_right")
				if move_dir == 0: move_dir = -1.0 
				world.set_blocked_direction(sign(move_dir))

func _on_area_exited(area: Area2D) -> void:
	print("Water Area Exited! Area: ", area.name) # DEBUG
	if area.name == "PlayerArea":
		player_in_range = false
		print("player_in_range after exited: ", player_in_range) # DEBUG
		if interact_label:
			interact_label.visible = false
		
		var world = find_parent("World")
		if world and world.has_method("set_blocked_direction"):
			world.set_blocked_direction(0.0)

func _on_water_suck_animation_finished() -> void:
		if water_suck_animation.animation_finished.is_connected(_on_water_suck_animation_finished):
			water_suck_animation.animation_finished.disconnect(_on_water_suck_animation_finished)
		
		water_suck_animation.stop() # Stops animation, holds last frame
		water_suck_animation.frame = water_suck_animation.sprite_frames.get_frame_count("Water") - 1 # Explicitly set final frame (no water)
		Global.world_state["hoover_filled_with_water"] = true # Set flag that Hoover is filled
		Global.world_state["water_sucked"] = true # Keep this for general water state tracking
		
		if area_2d:
			area_2d.monitorable = false
			area_2d.input_pickable = false
			water_collision_shape.disabled = true # Disable collision
		
		# AI dialogue "Give me that!" persists for a short duration
		if ai_dialogue_label and ai_animated_sprite:
			get_tree().create_timer(3.0).timeout.connect(func():
				ai_dialogue_label.visible = false
				ai_animated_sprite.play("Idle")
			)
		
		if interact_label and player_in_range:
			interact_label.text = "Hoover is filled with water!"
			interact_label.visible = true
			get_tree().create_timer(2.0).timeout.connect(func():
				interact_label.visible = false
			)
		
		# Removed: water_suck_animation.visible = false
