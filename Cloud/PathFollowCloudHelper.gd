extends PathFollow2D

@export var initial_unit_offset: float = 0.0
@export var speed: float = 0.01

func _ready() -> void:
	progress_ratio = initial_unit_offset

func _process(delta: float) -> void:
	progress_ratio = fmod(progress_ratio + speed * delta, 1.0)
