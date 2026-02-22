extends Node2D

@export var rotation_speed: float = 2.0 
@export var fireball_scene: PackedScene = load("res://FX/fireball.tscn")

@onready var feeding_cam: Camera2D = $Globe/AI/FeedingCam
@onready var ai_sprite: AnimatedSprite2D = $Globe/AI/AnimatedSprite2D
@onready var ai_dialogue: Label = $Globe/AI/AI_Dialogue

var is_feeding: bool = false
var blocked_direction: float = 0.0 # 1: right, -1: left
var following_fireball: Node2D = null
var cam_original_pos: Vector2

func set_blocked_direction(dir: float) -> void:
	blocked_direction = dir

func _ready() -> void:
	rotation = Global.world_state["world_rotation"]
	if feeding_cam:
		feeding_cam.enabled = false
		cam_original_pos = feeding_cam.position
	if ai_dialogue:
		ai_dialogue.text = ""

func _process(delta: float) -> void:
	if following_fireball:
		feeding_cam.global_position = following_fireball.global_position
		return
		
	if is_feeding:
		return
		
	var direction := Input.get_axis("move_left", "move_right")
	
	if blocked_direction != 0 and sign(direction) == sign(blocked_direction):
		direction = 0
	
	if direction != 0:
		rotation -= direction * rotation_speed * delta
		Global.world_state["world_rotation"] = rotation

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
		var player_cam = player.find_child("Camera2D", true, false)
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
