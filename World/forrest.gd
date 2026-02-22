extends Node2D

var interact_label: Label
@onready var sprite: Sprite2D = $Area2D/ForrestSprite
@export var wood_item: Item = load("res://items/wood.tres")

var player_in_range: bool = false
var is_chopped: bool = false
var player_ref: Node2D = null

func _ready() -> void:
	interact_label = get_tree().root.find_child("InteractLabel", true, false)
	if interact_label:
		interact_label.visible = false
	
	# Track chopped trees
	if get_path() in Global.world_state["chopped_trees"]:
		is_chopped = true
		sprite.texture = load("res://assets/New/chopped_forrest.png")

func _input(event: InputEvent) -> void:
	if player_in_range and not is_chopped:
		if event.is_action_pressed("interact"):
			chop_down()

func chop_down() -> void:
	if player_ref and player_ref.has_method("collect_item"):
		if Global.current_item != null:
			if interact_label:
				interact_label.text = "My hands are full"
				interact_label.visible = true
			return
			
		if wood_item:
			player_ref.collect_item(wood_item)
			is_chopped = true
			Global.world_state["chopped_trees"].append(get_path())
			sprite.texture = load("res://assets/New/chopped_forrest.png")
			
			# "Collision"
			var world = get_tree().root.find_child("World", true, false)
			if world and world.has_method("set_blocked_direction"):
				world.set_blocked_direction(0.0)
				
			if interact_label:
				interact_label.text = ""
				interact_label.visible = false

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea": 
		player_in_range = true
		player_ref = area.get_parent()
		
		if not is_chopped:
			if interact_label:
				interact_label.visible = true
				interact_label.text = "Press E to chop down"
			
			var world = get_tree().root.find_child("World", true, false)
			if world and world.has_method("set_blocked_direction"):
				var move_dir = Input.get_axis("move_left", "move_right")
				if move_dir == 0: move_dir = 1.0 
				world.set_blocked_direction(sign(move_dir))

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = false
		player_ref = null
		if interact_label:
			interact_label.visible = false
		
		var world = get_tree().root.find_child("World", true, false)
		if world and world.has_method("set_blocked_direction"):
			world.set_blocked_direction(0.0)
