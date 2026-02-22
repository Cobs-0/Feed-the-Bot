extends CharacterBody2D

@onready var inventory: Sprite2D = $PlayerArea/Inventory
@onready var player_sprite: AnimatedSprite2D = $PlayerArea/PlayerSprite

const SPEED = 300.0

func _ready() -> void:
	update_inventory_visuals()

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		velocity.x = direction * SPEED
		player_sprite.flip_h = direction < 0
		player_sprite.play("Walk")
		inventory.position = Vector2(10 * direction, 0) # Position for facing direction
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		player_sprite.play("Idle")
		# Ensure inventory position is consistent even when idle
		inventory.position = Vector2(10 * (1 if not player_sprite.flip_h else -1), 0)
		
	move_and_slide()

func collect_item(item: Item) -> bool:
	if item == null:
		return false
		
	if Global.current_item == null:
		Global.current_item = item
		update_inventory_visuals()
		return true
	return false

func drop_item() -> void:
	print("MovablePlayer drop_item() called!") # DEBUG
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
