extends Node2D # Root node is now Node2D, consistent with other world objects

var player_in_range: bool = false
@onready var _dialogue_label: Label = $GuardCollisionBody/DialogueLabel
@onready var _area_2d: Area2D = $GuardCollisionBody/Area2D
@onready var _guard_static_body: StaticBody2D = $GuardCollisionBody
@onready var _collision_shape: CollisionShape2D = $GuardCollisionBody/CollisionShape2D
@onready var _guard_sprite: Sprite2D = $GuardCollisionBody/Area2D/Sprite2D
@onready var interact_label: Label = get_tree().root.find_child("InteractLabel", true, false)
@onready var world_node: Node2D = get_tree().root.find_child("World", true, false) # Add world_node reference

func _ready() -> void:
	_dialogue_label.visible = false
	
	if _area_2d:
		if not _area_2d.area_entered.is_connected(_on_area_entered):
			_area_2d.area_entered.connect(_on_area_entered)
		if not _area_2d.area_exited.is_connected(_on_area_exited):
			_area_2d.area_exited.connect(_on_area_exited)
	
	# Guard state if already knocked down
	if Global.world_state.get("guard_down", false):
		_guard_sprite.rotation_degrees = 90
		_guard_sprite.position = _guard_sprite.position + Vector2(25, 25) # Apply position adjustment on load
		if _collision_shape:
			_collision_shape.disabled = true
		_dialogue_label.visible = false
		player_in_range = false 

func _input(event: InputEvent) -> void:
	if not player_in_range or Global.world_state.get("guard_down", false): return # Don't react if guard is down

	if event.is_action_pressed("interact"):
		var player_node = get_tree().root.find_child("Player", true, false)
		if player_node and Global.current_item and Global.current_item.name == "Rock":
			_hit_with_rock(player_node)
		else:
			# Player interacts but doesn't have a rock
			if interact_label and not Global.world_state.get("guard_down", false):
				interact_label.text = "You need something to get past the Guard."
				interact_label.visible = true
				get_tree().create_timer(2.0).timeout.connect(func():
					interact_label.visible = false
				)


func _on_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = true
		if not Global.world_state.get("guard_down", false):
			_dialogue_label.text = "You can't get past sir... It's dangerous."
			_dialogue_label.visible = true
			if interact_label:
				interact_label.text = "Press E to Interact"
				interact_label.visible = true
			
			if world_node and world_node.has_method("set_blocked_direction"):
				var move_dir = Input.get_axis("move_left", "move_right")
				if move_dir == 0: move_dir = 1.0 
				world_node.set_blocked_direction(sign(move_dir))


func _on_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = false
		_dialogue_label.visible = false
		if interact_label:
			interact_label.visible = false
		
		if world_node and world_node.has_method("set_blocked_direction"):
			world_node.set_blocked_direction(0.0)

func _hit_with_rock(player_node: Node2D) -> void:
	Global.world_state["guard_down"] = true
	
	if player_node.has_method("drop_item"):
		player_node.drop_item() # Remove the rock from player's inventory

	_guard_sprite.rotation_degrees = 90
	_guard_sprite.position = _guard_sprite.position + Vector2(25, 25) # Position adjustment (corrected)

	if _collision_shape:
		_collision_shape.disabled = true
	
	_dialogue_label.visible = false # Hide Guard's own dialogue

	if interact_label:
		interact_label.text = "You knocked out the guard!"
		interact_label.visible = true
		get_tree().create_timer(2.0).timeout.connect(func():
			interact_label.visible = false
		)
