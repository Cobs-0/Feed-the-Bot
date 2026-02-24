# Cloud/cloud.gd
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var cloud_textures = [
    preload("res://assets/Clouds/Clouds1.png"),
    preload("res://assets/Clouds/Clouds2.png"),
    preload("res://assets/Clouds/Clouds3.png"),
    preload("res://assets/Clouds/Clouds4.png"),
    preload("res://assets/Clouds/Clouds5.png"),
    preload("res://assets/Clouds/Clouds6.png"),
    preload("res://assets/Clouds/Clouds7.png"),
    preload("res://assets/Clouds/Clouds8.png"),
    preload("res://assets/Clouds/Clouds9.png"),
    preload("res://assets/Clouds/Clouds10.png"),
    preload("res://assets/Clouds/Clouds11.png"),
    preload("res://assets/Clouds/Clouds12.png"),
    preload("res://assets/Clouds/Clouds13.png"),
    preload("res://assets/Clouds/Clouds14.png"),
    preload("res://assets/Clouds/Clouds15.png"),
    preload("res://assets/Clouds/Clouds16.png"),
    preload("res://assets/Clouds/Clouds17.png"),
    preload("res://assets/Clouds/Clouds18.png"),
    preload("res://assets/Clouds/Clouds19.png"),
    preload("res://assets/Clouds/Clouds20.png"),
]

func _ready() -> void:
    randomize() # Ensure random number generator is seeded
    
    # Set random texture
    sprite.texture = cloud_textures[randi() % cloud_textures.size()]
    
    # Randomize scale
    var random_scale = randf_range(0.5, 1.5)
    sprite.scale = Vector2(random_scale, random_scale)
    
    # Randomize rotation (optional, but adds variation)
    sprite.rotation_degrees = randf_range(-10, 10)