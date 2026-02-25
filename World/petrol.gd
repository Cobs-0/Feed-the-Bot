extends Node2D

@onready var petrol_area: Area2D = $PetrolArea
@onready var interact_label: Label = get_tree().root.find_child("InteractLabel", true, false)
@onready var player_ref: Node2D = get_tree().root.find_child("Player", true, false)

@export var petrol_item_resource: Item = load("res://items/petrol.tres")

var near_petrol: bool = false

func _ready() -> void:
	petrol_area.area_entered.connect(_on_petrol_area_entered)
	petrol_area.area_exited.connect(_on_petrol_area_exited)
	
	if Global.world_state.get("petrol_collected", false):
		queue_free() # Delete if already collected

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and near_petrol:
		collect_petrol()

func collect_petrol() -> void:
	if player_ref and player_ref.has_method("collect_item"):
		if player_ref.collect_item(petrol_item_resource):
			queue_free() 
			interact_label.text = ""
			interact_label.visible = false
			Global.world_state["petrol_collected"] = true
		else:
			interact_label.text = "My hands are full"
			interact_label.visible = true

func _on_petrol_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_petrol = true
		if not Global.world_state.get("petrol_collected", false):
			interact_label.text = "Press E to pick up Petrol"
			interact_label.visible = true

func _on_petrol_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		near_petrol = false
		interact_label.text = ""
		interact_label.visible = false
