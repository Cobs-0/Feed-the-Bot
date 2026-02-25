extends Node2D

@onready var inventory: Sprite2D = $PlayerArea/Inventory
@onready var player_sprite: AnimatedSprite2D = $PlayerArea/PlayerSprite

var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.stream = load("res://assets/SFX/Pickup.wav")
	update_inventory_visuals()

func _process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	if direction == 1:
		player_sprite.flip_h = false
		player_sprite.play("Walk")
		inventory.position = Vector2(10, 0) # Position for facing right
	elif direction == -1:
		player_sprite.flip_h = true
		player_sprite.play("Walk")
		inventory.position = Vector2(-10, 0) # Position for facing left
	else:
		player_sprite.play("Idle")
		if player_sprite.flip_h == false:
			inventory.position = Vector2(10, 0)
		else:
			inventory.position = Vector2(-10, 0)

func collect_item(item: Item) -> bool:
	if item == null:
		return false
		
	if Global.current_item == null:
		Global.current_item = item
		if audio_player:
			audio_player.play()
		update_inventory_visuals()
		return true
	return false

func drop_item() -> void:
	Global.current_item = null
	update_inventory_visuals()

func update_inventory_visuals() -> void:
	if inventory == null:
		return
		
	if Global.current_item:
		if Global.current_item.texture:
			inventory.texture = Global.current_item.texture
			inventory.scale = Vector2.ONE * Global.current_item.visual_scale
			inventory.visible = true
		else:
			inventory.visible = false
	else:
		inventory.visible = false
