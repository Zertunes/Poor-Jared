extends Node3D

var parallel_track_name : String = "ingamesongs"
var music_zone : String = "Shop"
var night : bool = false
var reset : bool = false

@onready var game_menu = $"../City/GameMenu"

#func _ready():
	#AudioManager.play_music(parallel_track_name)

func _process(delta):
	if !game_menu.joinlobby:
		if !(AudioManager.current_playback == AudioManager.tools.add_track(parallel_track_name, AudioManager.get_track_data(parallel_track_name))):
			AudioManager.play_music(parallel_track_name)
		
		if night:
			on_night()
		else:
			off_night()
		
		#reset = true
	else:
		#if reset:
		AudioManager.stop_all()
			#reset = false
	#print(reset)

func on_night():
	#AudioManager.play_music("Night", 0.5, 1.5, true)
	#AudioManager.change_loop("Night", 0, true)
	AudioManager.mute_layer(parallel_track_name, [], true)
	AudioManager.mute_layer(parallel_track_name, ["Night"], false, 1)

func off_night():
	#AudioManager.set_sequence(reset_theme)
	#AudioManager.set_destroy(true)
	AudioManager.mute_layer(parallel_track_name, [], true)
	AudioManager.mute_layer(parallel_track_name, [music_zone], false, 1)

func _on_daylight_body_entered(body):
	#if night: return
	if body.is_in_group("players"):
		AudioManager.mute_layer(parallel_track_name, [], true)
		AudioManager.mute_layer(parallel_track_name, ["Daylight"], false, 0.5)
		music_zone = "Daylight"

func _on_shop_body_entered(body):
	#if night: return
	if body.is_in_group("players"):
		AudioManager.mute_layer(parallel_track_name, [], true)
		AudioManager.mute_layer(parallel_track_name, ["Shop"], false, 0.25)
		music_zone = "Shop"

func _on_black_market_body_entered(body):
	#if night: return
	if body.is_in_group("players"):
		AudioManager.mute_layer(parallel_track_name, [], true)
		AudioManager.mute_layer(parallel_track_name, ["Parkour"], false, 0.25)
		music_zone = "Parkour"

func _on_mall_body_entered(body):
	#if night: return
	if body.is_in_group("players"):
		AudioManager.mute_layer(parallel_track_name, [], true)
		AudioManager.mute_layer(parallel_track_name, ["Mall"], false, 0.25)
		music_zone = "Mall"

func _on_park_body_entered(body):
	#if night: return
	if body.is_in_group("players"):
		AudioManager.mute_layer(parallel_track_name, [], true)
		AudioManager.mute_layer(parallel_track_name, ["Park"], false, 0.25)
		music_zone = "Park"
