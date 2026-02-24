# Cloud/CloudManager.gd
extends Node2D

@export var cloud_scene: PackedScene = preload("res://Cloud/cloud.tscn")
@export var num_clouds: int = 10
@export var cloud_y_offset: float = -200.0 # Vertical offset above the path
@export var cloud_speed_min: float = 0.005
@export var cloud_speed_max: float = 0.02

# No _cloud_path_follows array needed anymore

func _ready() -> void:
	randomize()
	var ground_path: Path2D = get_node("../Globe/Ground") # Corrected relative path
	# print("Ground path: ", ground_path) # DEBUG removed
	
	if ground_path:
		for i in range(num_clouds):
			var path_follow = PathFollow2D.new()
			# Attach the helper script to the PathFollow2D
			path_follow.set_script(preload("res://Cloud/PathFollowCloudHelper.gd"))
			path_follow.loop = true
			
			# Pass random speed and initial offset to the helper script
			path_follow.initial_unit_offset = randf() # Initial offset
			path_follow.speed = randf_range(cloud_speed_min, cloud_speed_max) # Speed
			
			ground_path.add_child(path_follow)
			
			var cloud_instance = cloud_scene.instantiate()
			path_follow.add_child(cloud_instance)
			
			cloud_instance.position = Vector2(0, cloud_y_offset) # Apply vertical offset
			
			# Optional: Randomize initial horizontal position slightly for more dispersion
			cloud_instance.position.x += randf_range(-50, 50)
	else:
		print("ERROR: Ground Path2D not found at expected path ../Globe/Ground")

# No _process function needed anymore, movement is handled by PathFollowCloudHelper.gd
