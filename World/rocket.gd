extends Node2D

var player_in_range: bool = false
@onready var area_2d: Area2D = $Area2D
@onready var ai_animated_sprite: AnimatedSprite2D = get_tree().root.find_child("World", true, false).get_node("Globe/AI/AnimatedSprite2D")
@onready var ai_dialogue_label: Label = get_tree().root.find_child("World", true, false).get_node("Globe/AI/AI_Dialogue")
@onready var interact_label: Label = get_tree().root.find_child("InteractLabel", true, false)

func _ready() -> void:
	if area_2d:
		if not area_2d.area_entered.is_connected(_on_area_entered):
			area_2d.area_entered.connect(_on_area_entered)
		if not area_2d.area_exited.is_connected(_on_area_exited):
			area_2d.area_exited.connect(_on_area_exited)

func _input(event: InputEvent) -> void:
	if not player_in_range: return
	if event.is_action_pressed("interact"):
		if Global.current_item and Global.current_item.name == "Petrol" and not Global.world_state["rocket_fueled"]:
			_fuel_rocket()
		elif Global.world_state["rocket_fueled"]:
			if interact_label:
				interact_label.text = "The rocket is already fueled!"
				interact_label.visible = true
				get_tree().create_timer(2.0).timeout.connect(func():
					interact_label.visible = false
				)
		else:
			if interact_label:
				interact_label.text = "I need something to fuel the rocket."
				interact_label.visible = true
				get_tree().create_timer(2.0).timeout.connect(func():
					interact_label.visible = false
				)

func _fuel_rocket() -> void:
	Global.world_state["rocket_fueled"] = true
	var petrol_dialogue = ""
	if Global.current_item and "ai_dialogue" in Global.current_item:
		petrol_dialogue = Global.current_item.ai_dialogue
	
	var world_node = get_tree().current_scene
	var ai_cam = world_node.find_child("FeedingCam", true, false)
	var player_cam = null
	
	var player_node = world_node.find_child("Player", true, false) # Renamed to player_node to avoid conflict with 'player' variable
	if player_node:
		player_cam = player_node.find_child("Camera2D", true, false)
		if player_node.has_method("drop_item"):
			player_node.drop_item() # Call drop_item to clear inventory and update visuals

	if ai_cam:
		ai_cam.enabled = true
		ai_cam.make_current()

	if ai_dialogue_label and ai_animated_sprite:
		ai_dialogue_label.text = petrol_dialogue if petrol_dialogue != "" else "That's some good fuel!"
		ai_dialogue_label.visible = true
		ai_animated_sprite.play("Talk")

		await get_tree().create_timer(4.0).timeout # Use await for the delay

		ai_dialogue_label.visible = false
		ai_animated_sprite.play("Idle")
	
	if player_cam:
		player_cam.make_current()
	if ai_cam:
		ai_cam.enabled = false

	if interact_label:
		interact_label.visible = false # Hide during dialogue

func _on_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = true
		if interact_label:
			if not Global.world_state["rocket_fueled"]:
				interact_label.text = "Press E to Fuel Rocket"
				interact_label.visible = true
			else:
				interact_label.text = "Rocket is fueled!"
				interact_label.visible = true


func _on_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = false
		if interact_label:
			interact_label.visible = false
