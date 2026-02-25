extends Control

@onready var main_label: Label = $ColorRect/MainLabel
@onready var with_help_label: Label = $"ColorRect/With Help"
@onready var title_sprite: Sprite2D = $ColorRect/Sprite2D

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	self.set_size(get_viewport_rect().size)
	
	# Initial states
	main_label.modulate.a = 0.0
	with_help_label.visible = false
	title_sprite.modulate.a = 0.0
	
	# Center the title sprite
	title_sprite.position = get_viewport_rect().size / 2
	
	# Start animation
	play_credits_animation()

func play_credits_animation() -> void:
	# 1. Show Title Sprite
	var title_tween = create_tween()
	title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# Fade in Title
	title_tween.tween_property(title_sprite, "modulate:a", 1.0, 1.0)
	# Wait 3 seconds
	title_tween.tween_interval(3.0)
	# Fade out Title
	title_tween.tween_property(title_sprite, "modulate:a", 0.0, 1.0)
	
	await title_tween.finished
	
	# 2. Start Label Scroll
	var scroll_duration = 8.0
	var viewport_size = get_viewport_rect().size
	
	# Prepare labels
	main_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	with_help_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	
	var initial_main_y = viewport_size.y + 50
	var target_main_y = viewport_size.y * 0.2
	
	main_label.position.y = initial_main_y
	main_label.modulate.a = 1.0 # Make visible for scroll
	
	with_help_label.visible = true
	with_help_label.modulate.a = 0.0
	with_help_label.position.y = initial_main_y + 150
	
	var credits_tween = create_tween().set_parallel(true)
	credits_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	credits_tween.tween_property(main_label, "position:y", target_main_y, scroll_duration)\
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	credits_tween.tween_property(with_help_label, "position:y", target_main_y + 150, scroll_duration)\
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	credits_tween.tween_property(with_help_label, "modulate:a", 1.0, 2.0).set_delay(1.0)
