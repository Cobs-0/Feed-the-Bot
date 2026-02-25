extends Node

var current_item = null:
	set(value):
		if value != current_item:
			print("Global.current_item changed from ", current_item, " to ", value)
			if value:
				print("New item name: ", value.name)
			current_item = value
	get:
		return current_item

var world_state = {
	"chopped_trees": [],
	"lantern_collected": false,
	"world_rotation": 0.0,
	"fence_destroyed": false,
	"cave_exited": false,
	"water_inspected": false,
	"water_sucked": false,
	"bridge_built": false,
	"artist_deposited": false,
	"hoover_filled_with_water": false,
	"hoover_collected": false,
	"rocket_fueled": false,
	"petrol_collected": false,
	"guard_down": false,
	"rock_collected": false,
	"mountain_collapsed": false,
	"world_darkened_by_house_exit": false,
	"world_reddened_by_mountain_collapse": false
}

var ending_triggered = false

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.volume_db = -10.0
	
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	play_music("res://assets/SFX/MainTheme.mp3")

func play_sfx(path: String) -> void:
	sfx_player.stream = load(path)
	sfx_player.play()

func play_music(path: String) -> void:
	if music_player.stream and music_player.stream.resource_path == path:
		return
	music_player.stream = load(path)
	music_player.play()

func fade_out_music(duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, duration)
	await tween.finished
	music_player.stop()

func boost_music_volume(target_db: float = 0.0, duration: float = 1.0) -> void:
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", target_db, duration)
