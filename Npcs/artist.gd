extends Node2D

@onready var artist_sprite: AnimatedSprite2D = $Area2D/ArtistSprite
@onready var dialogue_label: Label = $DialogueLabel

@export var artist_item: Item = load("res://items/artist_item.tres")

var player_in_range: bool = false
var is_talking: bool = false

func _ready() -> void:
	# Only spawn if cave has been exited
	if not Global.world_state["cave_exited"] or Global.world_state["artist_deposited"]:
		hide()
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
		set_process_input(false)
	else:
		show()
		$Area2D/CollisionShape2D.set_deferred("disabled", false)
		set_process_input(true)
	
	if dialogue_label:
		dialogue_label.text = ""

func _input(event: InputEvent) -> void:
	if not visible: return
	
	if event.is_action_pressed("interact") and player_in_range:
		if Global.world_state["water_inspected"]:
			pick_up()
		elif not is_talking:
			talk()

func pick_up() -> void:
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("collect_item"):
		if player.collect_item(artist_item):
			queue_free()
		else:
			var label = get_tree().current_scene.find_child("InteractLabel", true, false)
			if label:
				label.text = "My hands are full"

func talk() -> void:
	is_talking = true
	artist_sprite.play("Talk")
	dialogue_label.text = "What happened to the trees?, I loved those trees since I was a child!"
	
	# Wait for 3 seconds
	await get_tree().create_timer(3.0).timeout
	
	artist_sprite.play("Idle")
	dialogue_label.text = ""
	is_talking = false

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = true
		var label = get_tree().current_scene.find_child("InteractLabel", true, false)
		if label:
			label.text = "Press E to Talk"
			label.visible = true

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.name == "PlayerArea":
		player_in_range = false
		var label = get_tree().current_scene.find_child("InteractLabel", true, false)
		if label:
			label.text = ""
			label.visible = false
