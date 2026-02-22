extends Node2D

var player_in_range: bool = false
@onready var area_2d: Area2D = $Area2D
@onready var bridge_sprite_onready: Sprite2D = $Area2D/BridgeSprite

@export var bridge_sprite: Sprite2D 
var wipe_shader = preload("res://assets/shaders/wipe.gdshader")


func _ready() -> void:
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
	if not player_in_range: return
	
	if event.is_action_pressed("interact"):
		if Global.world_state["bridge_built"]:
			return
		inspect_water()

func inspect_water() -> void:
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

	var interact_label = world_node.find_child("InteractLabel", true, false)
	if interact_label:
		interact_label.text = "I can't get past."
		interact_label.visible = true
		
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(func():
			if interact_label.text == "I can't get past.":
				interact_label.visible = false
		)

	Global.world_state["water_inspected"] = true
	
	var ai_dialogue = world_node.find_child("AI_Dialogue", true, false)
	var ai_sprite = null
	
	var ai_node = world_node.find_child("AI", true, false)
	if ai_node:
		ai_sprite = ai_node.find_child("AnimatedSprite2D")
		
	if ai_dialogue and ai_sprite:
		ai_sprite.play("Talk")
		ai_dialogue.text = "If only I could paint."
		ai_dialogue.visible = true
		
		await get_tree().create_timer(4.0).timeout
		
		ai_dialogue.text = ""
		ai_dialogue.visible = false
		ai_sprite.play("Idle")
	
	if player_cam:
		player_cam.make_current()
	if ai_cam:
		ai_cam.enabled = false

func _on_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = true
		
		if not Global.world_state["bridge_built"]:
			var label = get_tree().current_scene.find_child("InteractLabel", true, false)
			if label:
				label.text = "Press E to Inspect"
				label.visible = true
			
			var world = find_parent("World")
			if world and world.has_method("set_blocked_direction"):
				var move_dir = Input.get_axis("move_left", "move_right")
				if move_dir == 0: move_dir = -1.0 
				world.set_blocked_direction(sign(move_dir))
		else:
			pass

func _on_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = false
		var label = get_tree().current_scene.find_child("InteractLabel", true, false)
		if label:
			label.visible = false
		
		var world = find_parent("World")
		if world and world.has_method("set_blocked_direction"):
			world.set_blocked_direction(0.0)
