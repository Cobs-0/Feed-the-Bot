extends Node2D

@onready var dialogue_label: Label = $DialogueLabel

func _ready() -> void:
	if dialogue_label:
		dialogue_label.text = ""

func say_pickup_line() -> void:
	if dialogue_label:
		dialogue_label.text = "Oh why'd you have to do that Mr..."
		await get_tree().create_timer(3.0).timeout
		dialogue_label.text = ""

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		if dialogue_label and not Global.world_state["lantern_collected"]:
			dialogue_label.text = "If you pick up that lantern there's gonna be trouble!"

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		if dialogue_label:
			dialogue_label.text = ""
