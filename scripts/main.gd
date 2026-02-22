extends Node2D

@onready var world_node: Node2D = $World
@onready var player_node: Node2D = $Player # MovablePlayer is instanced as Player in main.tscn
@onready var ai_dialogue_label: Label = $World/Globe/AI/AI_Dialogue # Directly reference the AI_Dialogue label
@onready var globe_node: AnimatedSprite2D = $World/Globe # Reference to the Globe node

func _ready() -> void:
	# Check if the player just exited the house
	if Global.world_state.has("exited_house") and Global.world_state["exited_house"] == true:
		# The world_rotation is already set in Global.world_state by room.gd
		# world_node's _ready() will pick this up automatically.
		
		# Trigger AI "Thirsty" dialogue
		set_ai_dialogue("Thirsty")
		
		# Reset global state flags
		Global.world_state["exited_house"] = false
		Global.world_state["last_exit_id"] = ""
		
		# Add a short delay to allow physics to settle after world rotation
		await get_tree().create_timer(0.1).timeout
		
		# Ensure movement is not blocked from previous scene
		if world_node.has_method("set_blocked_direction"):
			world_node.set_blocked_direction(0.0)

func set_ai_dialogue(text: String) -> void:
	if ai_dialogue_label:
		ai_dialogue_label.text = text
		ai_dialogue_label.visible = true
