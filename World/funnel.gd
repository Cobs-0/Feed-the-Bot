extends Node2D

var interact_label: Label
@onready var sprite: Sprite2D = $Area2D/FunnelSprite

var player_in_range: bool = false
var player_ref: Node2D = null

func _ready() -> void:
	interact_label = get_tree().root.find_child("InteractLabel", true, false)
	if interact_label:
		interact_label.visible = false

func _process(delta: float) -> void:
	if player_in_range:
		if Global.current_item != null:
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
	var success = false
	var item_ref = Global.current_item
	
	if player_ref and player_ref.has_method("drop_item"):
		player_ref.drop_item()
		success = true
	
	if Global.current_item != null:
		Global.current_item = null
		success = true
		if player_ref and player_ref.has_method("update_inventory_visuals"):
			player_ref.update_inventory_visuals()
	
	if success:
		if interact_label:
			interact_label.visible = false
		
		# Start feeding sequence
		var world = get_tree().root.find_child("World", true, false)
		if world and world.has_method("start_feeding_sequence"):
			world.start_feeding_sequence(item_ref)

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
