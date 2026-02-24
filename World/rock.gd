extends Node2D

@onready var rock_area: Area2D = $RockArea
@onready var interact_label: Label = get_tree().root.find_child("InteractLabel", true, false)
@onready var player_ref: Node2D = get_tree().root.find_child("Player", true, false)

@export var rock_item_resource: Item = load("res://items/rock.tres")

var near_rock: bool = false

func _ready() -> void:
	rock_area.area_entered.connect(_on_rock_area_entered)
	rock_area.area_exited.connect(_on_rock_area_exited)
	
	if Global.world_state.get("rock_collected", false):
		queue_free() # Delete if already collected

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and near_rock:
		collect_rock()

func collect_rock() -> void:
	if player_ref and player_ref.has_method("collect_item"):
		if player_ref.collect_item(rock_item_resource):
			queue_free() # Delete the rock node from the scene
			interact_label.text = ""
			interact_label.visible = false
			Global.world_state["rock_collected"] = true
		else:
			interact_label.text = "My hands are full"
			interact_label.visible = true

func _on_rock_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_rock = true
		if not Global.world_state.get("rock_collected", false):
			interact_label.text = "Press E to pick up Rock"
			interact_label.visible = true

func _on_rock_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_rock = false
		interact_label.text = ""
		interact_label.visible = false
