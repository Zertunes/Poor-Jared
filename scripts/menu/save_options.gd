extends Node

const SAVEOPTIONSFILE = "user://options.save"

var game_options_data = {}
var game_options_data_default = {}

func _ready():
	load_options_data()

func load_options_data():
	default_options()
	if not FileAccess.file_exists(SAVEOPTIONSFILE):
		write_options()
		save_data()
	else:
		read_options()
		save_data()
	
	if game_options_data == null:
		return

func write_options():
	var game_options_save_write = FileAccess.open(SAVEOPTIONSFILE, FileAccess.WRITE_READ)
	var json_string_save = JSON.stringify(default_options())
	game_options_save_write.store_string(json_string_save)
	print("Default data loaded because there was no file.")
	
	while game_options_save_write.get_position() < game_options_save_write.get_length():
		var json_string = game_options_save_write.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		var file_result = json.get_data()
		game_options_data = file_result
	game_options_save_write.close()

func read_options():
	var game_options_save_read = FileAccess.open(SAVEOPTIONSFILE, FileAccess.READ)
	while game_options_save_read.get_position() < game_options_save_read.get_length():
		var json_string = game_options_save_read.get_line()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		var file_result = json.get_data()
		game_options_data = file_result
	game_options_save_read.close()

func default_options():
	var local_language = OS.get_locale()
	game_options_data_default = {
		"display_mode": 0,
		"vsync_on": true,
		"max_fps": 600,
		"bloom_on": true,
		"brightness": 100,
		"master_volume": 50,
		"music_volume": 50,
		"sfx_volume": 50,
		"fov": 90,
		"mouse_sensitivity": 200,
		"display_fps": false,
		"display_speed": false,
		"view_bobbing": true,
		"fov_change": true,
#		"keybind1_forward": "W",
#		"keybind2_forward": null,
#		"keybind1_backward": "S",
#		"keybind2_backward": null,
#		"keybind1_left": "A",
#		"keybind2_left": null,
#		"keybind1_right": "D",
#		"keybind2_right": null,
#		"keybind1_jump": "Space",
#		"keybind2_jump": null,
#		"keybind1_crouch": "Ctrl",
#		"keybind2_crouch": null
		"sideways_tilt": true,
		"chromatic_abberation": true,
		"unfocus_pause": true,
		"language": local_language
		}
	if not FileAccess.file_exists(SAVEOPTIONSFILE):
		game_options_data = game_options_data_default
	if game_options_data == null:
		game_options_data = game_options_data_default

func save_data():
	var file = FileAccess.open(SAVEOPTIONSFILE, FileAccess.WRITE)
	var game_options_save = JSON.stringify(game_options_data)
	file.store_string(game_options_save)
