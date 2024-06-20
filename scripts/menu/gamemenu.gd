extends Node

signal disconnect_player(peer_id)

@onready var keybindings = [
	$GameMenu/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Forward/Label/Keybindings,
	$GameMenu/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Backward/Label/Keybindings,
	$GameMenu/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Left/Label/Keybindings,
	$GameMenu/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Right/Label/Keybindings,
	$GameMenu/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Jump/Label/Keybindings,
	$GameMenu/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Crouch/Label/Keybindings,
	$GameMenu/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Sprint/Label/Keybindings,
	$GameMenu/ControlsMenu/MarginContainer/VBoxContainer/Label/MarginContainer/VBoxContainer/Pause/Label/Keybindings,
	$GameMenu/ControlsMenu/MarginContainer/VBoxContainer/Label/MarginContainer/VBoxContainer/Console/Label/Keybindings
]

@onready var menus = {
	"game_menu": $GameMenu,
	"pause_menu": $GameMenu/PauseMenu,
	"options_menu": $GameMenu/OptionsMenu,
	"background": $GameMenu/Background,
	"controls_menu": $GameMenu/ControlsMenu,
	"key_select_menu": $GameMenu/KeySelectMenu,
	"confirm_menu": $GameMenu/ConfirmMenu
}

var player_on: bool = false
var pause: int = 0
var paused: bool = true
var singleplayer: bool = false
var pause_focus: bool = true
var joinlobby: bool = true

var confirmtype: int = 0

var console_window:bool = false

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	get_parent().get_node("JoinLobby").player_created.connect(_player_created)
	hide_menus()
	pause = 0
	
	for keybinding in keybindings:
		keybinding.button_keybind.connect(_button_keybind)
		keybinding.button_keybind_off.connect(_button_keybind_off)
	
	GlobalOptions.unfocus_pause_toggled.connect(_on_unfocus_pause_toggled)
	Panku.interactive_shell_visibility_changed.connect(_interactive_shell_visibility_changed)

func _interactive_shell_visibility_changed(visible):
	console_window = visible

func _process(delta):
	if pause == 0:
		paused = false
	else:
		paused = true
	
	if singleplayer == true: # pauses, literally, if singleplayer
		if paused == true:
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			get_tree().paused = false

func _notification(what):
	#var when_paused = paused
	#if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
		#print("focus in")
		#if when_paused == true:
			#paused = true
		#else:
			#paused = false
	if pause_focus == false:
		return
	if joinlobby == true:
		return
	#if player_on and !menus.key_select_menu.visible:
		#print(menus.key_select_menu.visible)
	if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
		if pause == 0:
				pause += 1

func _input(event):
	if player_on and !menus.key_select_menu.visible:
		if event.is_action_pressed("pause"):
			if pause == 0:
				pause += 1
			elif pause >= 1:
				pause -= 1
		if event.is_action_pressed("toggle_console"):
			if pause == 0:
				pause += 1
			elif pause >= 1:
				if console_window == true:
					pause = 0
	
	if pause > 0:
		menus.background.show()
		menus.game_menu.show()
		
		if pause == 1:
			menus.pause_menu.show()
			menus.options_menu.hide()
			menus.controls_menu.hide()
		elif pause == 2:
			menus.pause_menu.hide()
			menus.options_menu.show()
			menus.controls_menu.hide()
		elif pause == 3:
			menus.pause_menu.hide()
			menus.options_menu.hide()
			menus.controls_menu.show()
	else:
		hide_menus()
		confirmtype = 0
	
	if confirmtype > 0:
		menus.pause_menu.hide()
		menus.options_menu.hide()
		menus.controls_menu.hide()
		menus.confirm_menu.show()
	else:
		menus.confirm_menu.hide()

func hide_menus():
	for menu in menus.values():
		menu.hide()

func _on_resume_button_pressed():
	pause = 0

func _on_options_button_pressed():
	pause += 1

func _on_controls_button_pressed():
	pause += 1

func _on_back_button_options_pressed():
	pause -= 1

func _on_exit_button_pressed():
	confirmtype = 1
	#get_tree().quit()

func _on_menu_button_pressed():
	confirmtype = 2
	pass


func _player_created():
	player_on = true

func _button_keybind():
	pause += 1
	menus.key_select_menu.visible = true

func _button_keybind_off():
	pause -= 1
	menus.key_select_menu.visible = false

func _on_unfocus_pause_toggled(toggle):
	pause_focus = toggle


func _on_yes_button_pressed():
	if confirmtype == 1:
		emit_signal("disconnect_player", multiplayer.get_unique_id())
		get_tree().quit()
	elif confirmtype == 2:
		emit_signal("disconnect_player", multiplayer.get_unique_id())
		get_tree().change_scene_to_file("res://scenes/test.tscn")

func _on_no_button_pressed():
	confirmtype = 0
