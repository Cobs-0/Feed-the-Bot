extends Node2D

@onready var interact_label: Label = $CanvasLayer/InteractLabel
@onready var exit_node: Area2D = $Exit
@onready var exit2_node: Area2D = $Exit2
@onready var lantern_node: Area2D = $Lantern # "Hoover" item is represented by Lantern node
@onready var movable_player: Node2D = $MovablePlayer # Reference to the player node

@export var hoover_item_resource: Item = load("res://items/hoover.tres") # Assuming this item resource exists

var near_exit: bool = false
var near_exit2: bool = false
var near_lantern: bool = false
var blocked_direction: float = 0.0

func _ready() -> void:
	# Connect signals for exits and lantern
	exit_node.area_entered.connect(_on_Exit_area_entered)
	exit_node.area_exited.connect(_on_Exit_area_exited)
	exit2_node.area_entered.connect(_on_Exit2_area_entered)
	exit2_node.area_exited.connect(_on_Exit2_area_exited)
	lantern_node.area_entered.connect(_on_Lantern_area_entered)
	lantern_node.area_exited.connect(_on_Lantern_area_exited)
	
	interact_label.text = ""
	interact_label.visible = false
	
	if Global.world_state.get("hoover_collected", false):
		lantern_node.queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if near_lantern:
			collect_hoover()
		elif near_exit:
			exit_room("Exit1") # Indicate Exit 1 was used
		elif near_exit2:
			exit_room("Exit2") # Indicate Exit 2 was used

func collect_hoover() -> void:
	if movable_player.has_method("collect_item"):
		if movable_player.collect_item(hoover_item_resource):
			lantern_node.queue_free()
			interact_label.text = ""
			interact_label.visible = false
			Global.world_state["hoover_collected"] = true # Set flag that Hoover is collected
		else:
			interact_label.text = "My hands are full"
			interact_label.visible = true

func exit_room(exit_id: String) -> void:
	Global.world_state["exited_house"] = true
	Global.world_state["last_exit_id"] = exit_id
	Global.world_state["world_darkened_by_house_exit"] = true # Set flag for darkening world
	
	# Set world rotation based on which exit was used
	if exit_id == "Exit1":
		Global.world_state["world_rotation"] = 2.2
	elif exit_id == "Exit2":
		Global.world_state["world_rotation"] = 1.60800025463104
	
	get_tree().change_scene_to_file("res://scripts/main.tscn")

func _on_Exit_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_exit = true
		interact_label.text = "Press E to exit House (Left)"
		interact_label.visible = true

func _on_Exit_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_exit = false
		interact_label.text = ""
		interact_label.visible = false

func _on_Exit2_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_exit2 = true
		interact_label.text = "Press E to exit House (Right)"
		interact_label.visible = true

func _on_Exit2_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_exit2 = false
		interact_label.text = ""
		interact_label.visible = false

func _on_Lantern_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_lantern = true
		interact_label.text = "Press E to pick up Hoover"
		interact_label.visible = true

func _on_Lantern_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_lantern = false
		interact_label.text = ""
		interact_label.visible = false

func _on_rightwall_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		blocked_direction = 1.0
		movable_player.set_blocked_direction(blocked_direction)

func _on_rightwall_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		blocked_direction = 0.0
		movable_player.set_blocked_direction(blocked_direction)

func _on_leftwall_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		blocked_direction = -1.0
		movable_player.set_blocked_direction(blocked_direction)

func _on_leftwall_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		blocked_direction = 0.0
		movable_player.set_blocked_direction(blocked_direction)
