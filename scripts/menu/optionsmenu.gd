extends PanelContainer

# Video Options
@onready var display_mode_button = $MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/DisplayMode/Label/DisplayModeButton
@onready var v_sync_button = $MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/VSync/Label/VSyncButton
@onready var max_fps_slider = $MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/MaxFPS/Label/MaxFPSSlider
@onready var max_fps_text = $MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/MaxFPS/Label/MaxFPSText
@onready var bloom_button = $MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Bloom/Label/BloomButton
@onready var brightness_slider = $MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Brightness/Label/BrightnessSlider
@onready var brightness_text = $MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Brightness/Label/BrightnessText

# Audio Options
@onready var master_volume_slider = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/MasterVolume/Label/MasterVolumeSlider"
@onready var master_volume_text = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/MasterVolume/Label/MasterVolumeText"
@onready var music_volume_slider = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/MusicVolume/Label/MusicVolumeSlider"
@onready var music_volume_text = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/MusicVolume/Label/MusicVolumeText"
@onready var sfx_volume_slider = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/SFXVolume/Label/SFXVolumeSlider"
@onready var sfx_volume_text = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/SFXVolume/Label/SFXVolumeText"

# Gameplay Options
@onready var fov_slider = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/FOV/Label/FOVSlider"
@onready var fov_text = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/FOV/Label/FOVText"
@onready var sensitivity_slider = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/Sensitivity/Label/SensitivitySlider"
@onready var sensitivity_text = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/Sensitivity/Label/SensitivityText"
@onready var display_fps_button = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/DisplayFPS/Label/DisplayFPSButton"
@onready var display_speed_button = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/DisplaySpeed/Label/DisplaySpeedButton"
@onready var view_bobbing_button = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/ViewBobbing/Label/ViewBobbingButton"
@onready var fov_change_button = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/FOVChange/Label/FOVChangeButton"
@onready var sideways_tilt_button = $"MarginContainer/VBoxContainer/Label/Audio&GameplayMarginContainer/VBoxContainer/SidewaysTilt/Label/SidewaysTiltButton"
@onready var chromatic_abberation_button = $"MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/ChromaticAberration/Label/ChromaticAbberationButton"
@onready var unfocus_pause_button = $MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/UnfocusPause/Label/UnfocusPauseButton
@onready var language_button = $MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Language/Label/LanguageButton

var max_fps_default = 600
var brightness_default = 100
var master_volume_default = 50
var music_volume_default = 50
var sfx_volume_default = 50
var fov_default = 70
var mouse_sensitivity_default = 200

@onready var mainmenumusic = $"../../Sounds and Songs/MainMenuMusic"
@onready var buttonsound = $"../../Sounds and Songs/ButtonSound"
@onready var buttonbacksound = $"../../Sounds and Songs/ButtonBackSound"
@onready var keyenter = $"../../Sounds and Songs/KeyEnterSound"
@onready var slidersound = $"../../Sounds and Songs/SliderSound"

func _ready():
	await get_tree().create_timer(0.00001).timeout
	_load_saved_options()
	
	max_fps_default = SaveOptions.game_options_data_default.max_fps
	brightness_default = SaveOptions.game_options_data_default.brightness
	master_volume_default = SaveOptions.game_options_data_default.master_volume
	music_volume_default = SaveOptions.game_options_data_default.music_volume
	sfx_volume_default = SaveOptions.game_options_data_default.sfx_volume
	fov_default = SaveOptions.game_options_data_default.fov
	mouse_sensitivity_default = SaveOptions.game_options_data_default.mouse_sensitivity
	
	get_parent().get_parent().get_parent().get_node("JoinLobby").player_created.connect(_load_saved_options_ingame)

func _load_saved_options():
	await get_tree().create_timer(0.0001).timeout
	display_mode_button.select(1 if SaveOptions.game_options_data.display_mode else 0)
	GlobalOptions.toggle_fullscreen(SaveOptions.game_options_data.display_mode)
	v_sync_button.button_pressed = SaveOptions.game_options_data.vsync_on
	GlobalOptions.toggle_vsync(SaveOptions.game_options_data.vsync_on)
	max_fps_slider.value = SaveOptions.game_options_data.max_fps
	GlobalOptions.set_max_fps(float(SaveOptions.game_options_data.max_fps))
	bloom_button.button_pressed = SaveOptions.game_options_data.bloom_on
	GlobalOptions.toggle_bloom(SaveOptions.game_options_data.bloom_on)
	brightness_slider.value = SaveOptions.game_options_data.brightness
	GlobalOptions.update_brightness(float(SaveOptions.game_options_data.brightness)/100)
	
	master_volume_slider.value= SaveOptions.game_options_data.master_volume
	GlobalOptions.update_master_vol(float(SaveOptions.game_options_data.master_volume)-60)
	music_volume_slider.value= SaveOptions.game_options_data.music_volume
	GlobalOptions.update_music_vol(float(SaveOptions.game_options_data.music_volume)-60)
	sfx_volume_slider.value= SaveOptions.game_options_data.sfx_volume
	GlobalOptions.update_sfx_vol(float(SaveOptions.game_options_data.sfx_volume)-60)
	
	unfocus_pause_button.button_pressed = SaveOptions.game_options_data.unfocus_pause
	GlobalOptions.toggle_unfocus_pause(SaveOptions.game_options_data.unfocus_pause)
	language_button.select(SaveOptions.game_options_data.language if SaveOptions.game_options_data.language<8 else 0)
	GlobalOptions.toggle_language(SaveOptions.game_options_data.language)

func _load_saved_options_ingame():
	await get_tree().create_timer(0.00001).timeout
	fov_slider.value = SaveOptions.game_options_data.fov
	GlobalOptions.update_fov(SaveOptions.game_options_data.fov)
	sensitivity_slider.value = SaveOptions.game_options_data.mouse_sensitivity
	GlobalOptions.update_mouse_sens(float(SaveOptions.game_options_data.mouse_sensitivity)/100000)
	display_fps_button.button_pressed = SaveOptions.game_options_data.display_fps
	GlobalOptions.toggle_fps_display(SaveOptions.game_options_data.display_fps)
	display_speed_button.button_pressed = SaveOptions.game_options_data.display_speed
	GlobalOptions.toggle_speed_display(SaveOptions.game_options_data.display_speed)
	view_bobbing_button.button_pressed = SaveOptions.game_options_data.view_bobbing
	GlobalOptions.toggle_view_bobbing(SaveOptions.game_options_data.view_bobbing)
	fov_change_button.button_pressed = SaveOptions.game_options_data.fov_change
	GlobalOptions.toggle_fov_change(SaveOptions.game_options_data.fov_change)
	sideways_tilt_button.button_pressed = SaveOptions.game_options_data.sideways_tilt
	GlobalOptions.toggle_sideways_tilt(SaveOptions.game_options_data.sideways_tilt)
	chromatic_abberation_button.button_pressed = SaveOptions.game_options_data.chromatic_abberation
	GlobalOptions.toggle_chromatic_abberation(SaveOptions.game_options_data.chromatic_abberation)

# ------------------------[VIDEO]---------------------------
func _on_display_mode_button_item_selected(index):
	buttonsound.play()
	GlobalOptions.toggle_fullscreen(index)


func _on_v_sync_button_toggled(button_pressed):
	buttonsound.play()
	GlobalOptions.toggle_vsync(button_pressed)



func _on_max_fps_slider_value_changed(value):
	slidersound.play()
	GlobalOptions.set_max_fps(value)
	
	if value >= max_fps_slider.max_value:
		max_fps_text.text = TranslationServer.translate("§ob§max")
	else:
		max_fps_text.text = str(value)

func _on_max_fps_text_text_submitted(new_text):
	keyenter.play()
	if new_text == "r":
		new_text = max_fps_default
	elif float(new_text) >= max_fps_slider.max_value:
		new_text = max_fps_slider.max_value
		max_fps_text.text = str(max_fps_slider.max_value)
	elif float(new_text) <= max_fps_slider.min_value:
		new_text = max_fps_slider.min_value
		max_fps_text.text = str(max_fps_slider.min_value)
	else:
		float(new_text)
	
	max_fps_slider.value = float(new_text)
	GlobalOptions.set_max_fps(float(new_text))

func _on_max_fps_text_focus_exited():
	max_fps_slider.value = float(max_fps_slider.value)
	if float(max_fps_text.text) >= max_fps_slider.max_value:
		max_fps_text.text = TranslationServer.translate("§ob§max")
	else:
		max_fps_text.text = str(max_fps_slider.value)
	



func _on_bloom_button_toggled(button_pressed):
	buttonsound.play()
	GlobalOptions.toggle_bloom(button_pressed)


func _on_brightness_slider_value_changed(value):
	slidersound.play()
	GlobalOptions.update_brightness(value/100)
	brightness_text.text = str(value)

func _on_brightness_text_text_submitted(new_text):
	keyenter.play()
	if new_text == "r":
		new_text = brightness_default
	elif float(new_text) >= brightness_slider.max_value:
		new_text = brightness_slider.max_value
		brightness_text.text = str(brightness_slider.max_value)
	elif float(new_text) <= brightness_slider.min_value:
		new_text = brightness_slider.min_value
		brightness_text.text = str(brightness_slider.min_value)
	else:
		float(new_text)
	
	brightness_slider.value = float(new_text)
	GlobalOptions.update_brightness(float(new_text)/100)

func _on_brightness_text_focus_exited():
	brightness_slider.value = float(brightness_slider.value)
	brightness_text.text = str(brightness_slider.value)



# ------------------------[AUDIO]---------------------------
func _on_master_volume_slider_value_changed(value):
	slidersound.play()
	GlobalOptions.update_master_vol(value-60)
	master_volume_text.text = str(value)

func _on_master_volume_text_text_submitted(new_text):
	keyenter.play()
	if new_text == "r":
		new_text = master_volume_default
	elif float(new_text) >= master_volume_slider.max_value:
		new_text = master_volume_slider.max_value
		master_volume_text.text = str(master_volume_slider.max_value)
	elif float(new_text) <= master_volume_slider.min_value:
		new_text = master_volume_slider.min_value
		master_volume_text.text = str(master_volume_slider.min_value)
	else:
		float(new_text)
	
	master_volume_slider.value = float(new_text)
	GlobalOptions.update_master_vol(float(new_text)-60)

func _on_master_volume_text_focus_exited():
	master_volume_slider.value = float(master_volume_slider.value)
	master_volume_text.text = str(master_volume_slider.value)



func _on_music_volume_slider_value_changed(value):
	slidersound.play()
	GlobalOptions.update_music_vol(value-60)
	music_volume_text.text = str(value)

func _on_music_volume_text_text_submitted(new_text):
	keyenter.play()
	if new_text == "r":
		new_text = music_volume_default
	elif float(new_text) >= music_volume_slider.max_value:
		new_text = music_volume_slider.max_value
		music_volume_text.text = str(music_volume_slider.max_value)
	elif float(new_text) <= music_volume_slider.min_value:
		new_text = music_volume_slider.min_value
		music_volume_text.text = str(music_volume_slider.min_value)
	else:
		float(new_text)
	
	music_volume_slider.value = float(new_text)
	GlobalOptions.update_music_vol(float(new_text)-60)
	
func _on_music_volume_text_focus_exited():
	music_volume_slider.value = float(music_volume_slider.value)
	music_volume_text.text = str(music_volume_slider.value)



func _on_sfx_volume_slider_value_changed(value):
	slidersound.play()
	GlobalOptions.update_sfx_vol(value-60)
	sfx_volume_text.text = str(value)

func _on_sfx_volume_text_text_submitted(new_text):
	keyenter.play()
	if new_text == "r":
		new_text = sfx_volume_default
	elif float(new_text) >= sfx_volume_slider.max_value:
		new_text = sfx_volume_slider.max_value
		sfx_volume_text.text = str(sfx_volume_slider.max_value)
	elif float(new_text) <= sfx_volume_slider.min_value:
		new_text = sfx_volume_slider.min_value
		sfx_volume_text.text = str(sfx_volume_slider.min_value)
	else:
		float(new_text)
	
	sfx_volume_slider.value = float(new_text)
	GlobalOptions.update_sfx_vol(float(new_text)-60)

func _on_sfx_volume_text_focus_exited():
	sfx_volume_slider.value = float(sfx_volume_slider.value)
	sfx_volume_text.text = str(sfx_volume_slider.value)



# ------------------------[GAMEPLAY]---------------------------
func _on_fov_slider_value_changed(value):
	slidersound.play()
	GlobalOptions.update_fov(value)
	#var locale_translations = {
		#"en": "§ob§quake_pro",
		#"pt": "§ob§quake_pro",
		#"ja": "§ob§quake_pro",
		#"sr": "§ob§quake_pro",
		#"de": "§ob§quake_pro",
		#"fr": "§ob§quake_pro"
	#}
	if value >= fov_slider.max_value:
		#if locale_translations.has(TranslationServer.get_locale()):
			#fov_text.text = locale_translations[TranslationServer.get_locale()]
		#else:
			#fov_text.text = "§ob§quake_pro"
		fov_text.text = TranslationServer.translate("§ob§quake_pro")
	elif value <= fov_slider.min_value:
		fov_text.text = TranslationServer.translate("§ob§zoomer")
	else:
		fov_text.text = str(value)

func _on_fov_text_text_submitted(new_text):
	keyenter.play()
	if new_text == "r":
		new_text = fov_default
	elif float(new_text) >= fov_slider.max_value:
		new_text = fov_slider.max_value
		fov_text.text = str(fov_slider.max_value)
	elif float(new_text) <= fov_slider.min_value:
		new_text = fov_slider.min_value
		fov_text.text = str(fov_slider.min_value)
	else:
		float(new_text)
	
	fov_slider.value = float(new_text)
	GlobalOptions.update_fov(float(new_text))

func _on_fov_text_focus_exited():
	fov_slider.value = float(fov_slider.value)
	if float(fov_text.text) >= fov_slider.max_value:
		fov_text.text = TranslationServer.translate("§ob§quake_pro")
	elif float(fov_text.text) <= fov_slider.min_value:
		fov_text.text = TranslationServer.translate("§ob§zoomer")
	else:
		fov_text.text = str(fov_slider.value)



func _on_sensitivity_slider_value_changed(value):
	slidersound.play()
	GlobalOptions.update_mouse_sens(value/100000)
	sensitivity_text.text = str(value)

func _on_sensitivity_text_text_submitted(new_text):
	keyenter.play()
	if new_text == "r":
		new_text = mouse_sensitivity_default
	elif float(new_text) >= sensitivity_slider.max_value:
		new_text = sensitivity_slider.max_value
		sensitivity_text.text = str(sensitivity_slider.max_value)
	elif float(new_text) <= sensitivity_slider.min_value:
		new_text = sensitivity_slider.min_value
		sensitivity_text.text = str(sensitivity_slider.min_value)
	else:
		float(new_text)
	
	sensitivity_slider.value = float(new_text)
	GlobalOptions.update_mouse_sens(float(new_text)/100000)

func _on_sensitivity_text_focus_exited():
	sensitivity_slider.value = float(sensitivity_slider.value)
	sensitivity_text.text = str(sensitivity_slider.value)



func _on_display_fps_button_toggled(button_pressed):
	buttonsound.play()
	GlobalOptions.toggle_fps_display(button_pressed)


func _on_display_speed_button_toggled(button_pressed):
	buttonsound.play()
	GlobalOptions.toggle_speed_display(button_pressed)


func _on_view_bobbing_button_toggled(button_pressed):
	buttonsound.play()
	GlobalOptions.toggle_view_bobbing(button_pressed)


func _on_fov_change_button_toggled(button_pressed):
	buttonsound.play()
	GlobalOptions.toggle_fov_change(button_pressed)

func _on_sideways_tilt_button_toggled(button_pressed):
	buttonsound.play()
	GlobalOptions.toggle_sideways_tilt(button_pressed)

func _on_chromatic_abberation_button_toggled(button_pressed):
	buttonsound.play()
	GlobalOptions.toggle_chromatic_abberation(button_pressed)

func _on_unfocus_pause_button_toggled(button_pressed):
	buttonsound.play()
	GlobalOptions.toggle_unfocus_pause(button_pressed)

func _on_language_button_item_selected(index):
	buttonsound.play()
	GlobalOptions.toggle_language(index)


func _on_display_mode_button_item_focused(index):
	buttonsound.play()

func _on_language_button_item_focused(index):
	buttonsound.play()
