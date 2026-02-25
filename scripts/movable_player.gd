extends CharacterBody2D

@onready var inventory: Sprite2D = $PlayerArea/Inventory
@onready var player_sprite: AnimatedSprite2D = $PlayerArea/PlayerSprite

const SPEED = 300.0
var _blocked_direction: float = 0.0
var audio_player: AudioStreamPlayer2D

func set_blocked_direction(dir: float) -> void:
	_blocked_direction = dir

func _ready() -> void:
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.stream = load("res://assets/SFX/Pickup.wav")
	update_inventory_visuals()

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if _blocked_direction != 0 and sign(direction) == sign(_blocked_direction):
		direction = 0
	
	if direction != 0:
		velocity.x = direction * SPEED
		player_sprite.flip_h = direction < 0
		player_sprite.play("Walk")
		inventory.position = Vector2(10 * direction, 0) 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		player_sprite.play("Idle")
		inventory.position = Vector2(10 * (1 if not player_sprite.flip_h else -1), 0)
		
	move_and_slide()

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
