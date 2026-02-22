extends Node2D

var interact_label: Label
@onready var sprite: Sprite2D = $Area2D/FunnelSprite
@onready var ai_animated_sprite: AnimatedSprite2D = get_tree().root.find_child("World", true, false).get_node("Globe/AI/AnimatedSprite2D") # New AI reference
@onready var ai_dialogue_label: Label = get_tree().root.find_child("World", true, false).get_node("Globe/AI/AI_Dialogue") # New AI reference

var player_in_range: bool = false
var player_ref: Node2D = null

func _ready() -> void:
	interact_label = get_tree().root.find_child("InteractLabel", true, false)
	if interact_label:
		interact_label.visible = false

func _process(delta: float) -> void:
	if player_in_range:
		if Global.current_item != null and Global.current_item.name == "Hoover" and Global.world_state.get("hoover_filled_with_water", false):
			if interact_label:
				interact_label.text = "Press E to pour water from Hoover"
				interact_label.visible = true
		elif Global.current_item != null:
			if interact_label:
				interact_label.text = "Press E to deposit " + Global.current_item.name
				interact_label.visible = true
		else:
			if interact_label:
				interact_label.visible = false

func _input(event: InputEvent) -> void:
	if player_in_range and Global.current_item != null:
		if event.is_action_pressed("interact"):
			deposit()

func deposit() -> void:
	var current_item_in_inventory = Global.current_item
	
	if current_item_in_inventory == null:
		if interact_label:
			interact_label.text = "Nothing to deposit!"
			interact_label.visible = true
			get_tree().create_timer(1.5).timeout.connect(func():
				interact_label.visible = false
			)
		return

	# New logic: Prevent dumping empty Hoover
	if current_item_in_inventory.name == "Hoover" and not Global.world_state.get("hoover_filled_with_water", false):
		if ai_dialogue_label and ai_animated_sprite:
			ai_dialogue_label.text = "I don't want that!"
			ai_dialogue_label.visible = true
			ai_animated_sprite.play("Talk")
			get_tree().create_timer(3.0).timeout.connect(func():
				ai_dialogue_label.visible = false
				ai_animated_sprite.play("Idle")
			)
		if interact_label: # Clear interact label after AI speaks
			interact_label.visible = false
		return # Prevent deposit of empty Hoover
		
	var success = false
	var item_for_feeding = current_item_in_inventory # Default item to feed

	# Check for filled Hoover
	if current_item_in_inventory.name == "Hoover" and Global.world_state.get("hoover_filled_with_water", false):
		# Special handling for filled Hoover (water)
		
		# Drop Hoover from player inventory (to re-add empty one)
		if player_ref and player_ref.has_method("drop_item"):
			player_ref.drop_item() 
			success = true
		
		# Reset the Hoover filled state
		Global.world_state["hoover_filled_with_water"] = false
		
		# Prepare item to pass to AI (representing water)
		item_for_feeding = load("res://items/hoover.tres").duplicate() # Use hoover.tres as base
		item_for_feeding.name = "Water" # Set name to trigger specific dialogue in AI

		# We do NOT re-collect the empty hoover here, as per user's request.
		# It's taken out of inv.
		
	else:
		# Generic item deposit (e.g., wood, empty Hoover, etc.)
		if player_ref and player_ref.has_method("drop_item"):
			player_ref.drop_item() # This sets Global.current_item to null and updates visuals
			success = true
	
	if success:
		if interact_label:
			interact_label.visible = false
		
		# Start feeding sequence
		var world = get_tree().root.find_child("World", true, false)
		if world and world.has_method("start_feeding_sequence"):
			world.start_feeding_sequence(item_for_feeding) # Pass the determined item
	else:
		if interact_label:
			interact_label.text = "Failed to deposit " + current_item_in_inventory.name
			interact_label.visible = true
			get_tree().create_timer(2.0).timeout.connect(func():
				interact_label.visible = false
			)


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea": 
		player_in_range = true
		player_ref = area.get_parent()

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = false
		player_ref = null
		if interact_label:
			interact_label.visible = false
