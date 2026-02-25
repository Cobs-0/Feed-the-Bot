extends Node2D

@export var cloud_scene: PackedScene = preload("res://Cloud/cloud.tscn")
@export var num_clouds: int = 10
@export var cloud_y_offset: float = -200.0 
@export var cloud_speed_min: float = 0.005
@export var cloud_speed_max: float = 0.02


func _ready() -> void:
	randomize()
	var ground_path: Path2D = get_node("../Globe/Ground") 
	
	if ground_path:
		for i in range(num_clouds):
			var path_follow = PathFollow2D.new()
			path_follow.set_script(preload("res://Cloud/PathFollowCloudHelper.gd"))
			path_follow.loop = true
			
			path_follow.initial_unit_offset = randf() 
			path_follow.speed = randf_range(cloud_speed_min, cloud_speed_max) 
			
			ground_path.add_child(path_follow)
			
			var cloud_instance = cloud_scene.instantiate()
			path_follow.add_child(cloud_instance)
			
			cloud_instance.position = Vector2(0, cloud_y_offset) 
			
			cloud_instance.position.x += randf_range(-50, 50)
	else:
		print("ERROR: Ground Path2D not found at expected path ../Globe/Ground")
