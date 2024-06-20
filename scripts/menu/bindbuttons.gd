extends Node

signal button_keybind_off
signal button_keybind

@onready var button1: Button = $BindButton
@onready var button2: Button = $BindButton2
@onready var un_button1: TextureButton = $UnbindButton
@onready var un_button2: TextureButton = $UnbindButton2
@onready var blank1 = 1
@onready var blank2 = 1
@onready var mouse_in1 = 0
@onready var mouse_in2 = 0
@onready var first = null
@onready var second = null
@onready var entering = 1
@export var action: String = "forward"

func _ready():
#	loading_keybinds()
	
	_key_checker()
	button1.set_process_unhandled_key_input(false)
	button2.set_process_unhandled_key_input(false)
	display_keys()
	un_button1.hide()
	un_button2.hide()

func _key_checker():
	var keyEvents = InputMap.action_get_events(action)
	if keyEvents.size() >= 1:
		first = keyEvents[0]
	else:
		first = null
	if keyEvents.size() >= 2:
		second = keyEvents[1]
	else:
		second = null

# Update the display of keys.
func display_keys():
	if first == null:
		button1.text = "-"
		blank1 = 1
		un_button1.hide()
	else:
		button1.text = "%s" % first.as_text()
		blank1 = 0
	
	if second == null:
		button2.text = "-"
		blank2 = 1
		un_button2.hide()
	else:
		button2.text = "%s" % second.as_text()
		blank2 = 0

func _on_bind_button_toggled(button_pressed):
	if entering == 1:
		emit_signal("button_keybind")
		entering = 0
	button1.set_process_unhandled_key_input(button_pressed)
	if button1.button_pressed:
		button1.text = "..."
		un_button1.hide()
	else:
		display_keys()

func _on_bind_button_2_toggled(button_pressed):
	if entering == 1:
		emit_signal("button_keybind")
		entering = 0
	button2.set_process_unhandled_key_input(button_pressed)
	if button2.button_pressed:
		button2.text = "..."
		un_button2.hide()
	else:
		display_keys()

func _input(key):
	if key is InputEventMouseButton and entering == 0:
		if button1.button_pressed:
			remap_key(key, 1)
			button1.button_pressed = false
			emit_signal("button_keybind_off")
			entering = 1
		
		if button2.button_pressed:
			remap_key(key, 2)
			button2.button_pressed = false
			emit_signal("button_keybind_off")
			entering = 1
			_key_checker()

func _unhandled_key_input(event):
	if button1.button_pressed:
		remap_key(event, 1)
		button1.button_pressed = false
		emit_signal("button_keybind_off")
		entering = 1
	
	if button2.button_pressed:
		remap_key(event, 2)
		button2.button_pressed = false
		emit_signal("button_keybind_off")
		entering = 1
		_key_checker()

func remap_key(event, button):
	if button == 1:
		# Change the event in this game instance
		InputMap.action_erase_event(action, first)
		InputMap.action_add_event(action, event)
		first = InputMap.action_get_events(action)[0]
		InputMap.action_erase_event(action, first)
		InputMap.action_add_event(action, first)
		button1.text = "%s" % event.as_text()
		_key_checker()
		# Show unbind button if mouse is in the button
		blank1 = 0
		if mouse_in1 == 1:
			un_button1.show()
		else:
			un_button1.hide()
		# Save keybinds to save_keybinds
		saving_keybinds(event, 1)
	
	if button == 2:
		# Change the event in this game instance
		InputMap.action_erase_event(action, second)
		InputMap.action_add_event(action, event)
		button2.text = "%s" % event.as_text()
		_key_checker()
		# Show unbind button if mouse is in the button and it isn't the same as the first
		blank2 = 0
		if InputMap.action_get_events(action).size() >= 2:
			if mouse_in2 == 1:
				un_button2.show()
			else:
				un_button2.hide()
		# Save keybinds to save_keybinds
		saving_keybinds(event, 2)

func saving_keybinds(key, button):
	_key_checker()
	
	if button == 1:
#		var keybind_key_save = "keybind1_" + action
		SaveKeybinds.keymaps[action] = [key, second]
#		SaveOptions.game_options_data[keybind_key_save] = key
	if button == 2:
#		var keybind_key_save = "keybind2_" + action
		SaveKeybinds.keymaps[action] = [first, key]
#		SaveOptions.game_options_data[keybind_key_save] = key
	SaveKeybinds.save_keymap()
#	SaveOptions.save_data()

#func loading_keybinds():
#	var keybind_key_save1 = "keybind1_" + action
#	var keybind_key_save2 = "keybind2_" + action
#	InputMap.action_erase_events(action)
#	InputMap.action_add_event(action, keybind_key_save1)
#	InputMap.action_add_event(action, keybind_key_save2)
#	button1.text = SaveOptions.game_options_data[keybind_key_save1]
#	button2.text = SaveOptions.game_options_data[keybind_key_save2]


func _on_bind_button_mouse_entered():
	mouse_in1 = 1
	if blank1 == 0:
		un_button1.show()

func _on_bind_button_mouse_exited():
	mouse_in1 = 0
	if blank1 == 0:
		un_button1.hide()

func _on_bind_button_2_mouse_entered():
	mouse_in2 = 1
	if blank2 == 0:
		un_button2.show()

func _on_bind_button_2_mouse_exited():
	mouse_in2 = 0
	if blank2 == 0:
		un_button2.hide()

func _on_unbind_button_mouse_entered():
	mouse_in1 = 1
	if blank1 == 0:
		un_button1.show()

func _on_unbind_button_mouse_exited():
	mouse_in1 = 0
	if blank1 == 0:
		un_button1.hide()
	
func _on_unbind_button_2_mouse_entered():
	mouse_in2 = 1
	if blank2 == 0:
		un_button2.show()

func _on_unbind_button_2_mouse_exited():
	mouse_in2 = 0
	if blank2 == 0:
		un_button2.hide()



func _on_unbind_button_pressed():
	blank1 = 1
	un_button1.hide()
	InputMap.action_erase_event(action, first)
	_key_checker()
	display_keys()
	SaveKeybinds.keymaps[action] = [first, second]
	SaveKeybinds.save_keymap()

func _on_unbind_button_2_pressed():
	blank2 = 1
	un_button2.hide()
	InputMap.action_erase_event(action, second)
	_key_checker()
	display_keys()
	SaveKeybinds.keymaps[action] = [first, second]
	SaveKeybinds.save_keymap()
