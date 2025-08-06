extends Node

#signal language_change()

signal fps_displayed(value)
signal bloom_toggled(value)
signal brightness_updated(value)
signal fov_updated(value)
signal mouse_sens_updated(value)
signal speed_displayed(value)
signal view_bobbing_toggled(value)
signal fov_change_toggled(value)
#signal max_fps_number(value)
signal sideways_tilt_toggled(value)
signal chromatic_abberation_toggled(value)
signal unfocus_pause_toggled(value)

func toggle_fullscreen(index):
	if index == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif index == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	SaveOptions.game_options_data.display_mode = index
	SaveOptions.save_data()
func toggle_vsync(toggle):
	if toggle == true:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	elif toggle == false:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	SaveOptions.game_options_data.vsync_on = toggle
	SaveOptions.save_data()
func set_max_fps(value):
	Engine.max_fps = value if value < 600 else 0
	#emit_signal("max_fps_number", value)
	
	SaveOptions.game_options_data.max_fps = value if value < 600 else 600
	SaveOptions.save_data()
func toggle_bloom(value):
	emit_signal("bloom_toggled", value)
	
	SaveOptions.game_options_data.bloom_on = value
	SaveOptions.save_data()
func update_brightness(value):
	emit_signal("brightness_updated", value)
	
	SaveOptions.game_options_data.brightness = (value*100)
	SaveOptions.save_data()

func update_master_vol(vol):
	AudioServer.set_bus_volume_db(0, vol if vol > -60 else -9999)
	
	SaveOptions.game_options_data.master_volume = (vol+60)
	SaveOptions.save_data()

func update_music_vol(vol):
	AudioServer.set_bus_volume_db(1, vol if vol > -60 else -9999)
	
	SaveOptions.game_options_data.music_volume = (vol+60)
	SaveOptions.save_data()
func update_sfx_vol(vol):
	AudioServer.set_bus_volume_db(2, vol if vol > -60 else -9999)
	
	SaveOptions.game_options_data.sfx_volume = (vol+60)
	SaveOptions.save_data()
func update_fov(value):
	emit_signal("fov_updated", value)
	
	SaveOptions.game_options_data.fov = value
	SaveOptions.save_data()

func update_mouse_sens(value):
	emit_signal("mouse_sens_updated", value)
	
	SaveOptions.game_options_data.mouse_sensitivity = (value*100000)
	SaveOptions.save_data()
func toggle_fps_display(toggle):
	emit_signal("fps_displayed", toggle)
	
	SaveOptions.game_options_data.display_fps = toggle
	SaveOptions.save_data()
func toggle_speed_display(toggle):
	emit_signal("speed_displayed", toggle)
	
	SaveOptions.game_options_data.display_speed = toggle
	SaveOptions.save_data()
func toggle_view_bobbing(toggle):
	emit_signal("view_bobbing_toggled", toggle)
	
	SaveOptions.game_options_data.view_bobbing = toggle
	SaveOptions.save_data()
func toggle_fov_change(toggle):
	emit_signal("fov_change_toggled", toggle)
	
	SaveOptions.game_options_data.fov_change = toggle
	SaveOptions.save_data()
func toggle_sideways_tilt(toggle):
	emit_signal("sideways_tilt_toggled", toggle)
	
	SaveOptions.game_options_data.sideways_tilt = toggle
	SaveOptions.save_data()
func toggle_chromatic_abberation(toggle):
	emit_signal("chromatic_abberation_toggled", toggle)
	
	SaveOptions.game_options_data.chromatic_abberation = toggle
	SaveOptions.save_data()
func toggle_unfocus_pause(toggle):
	emit_signal("unfocus_pause_toggled", toggle)
	
	SaveOptions.game_options_data.unfocus_pause = toggle
	SaveOptions.save_data()
#func toggle_language(lang):
	#LanguageManager.change_language(lang)
