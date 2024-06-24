extends Node

signal player_created

@onready var game_menu = get_parent().get_node("GameMenu")
@onready var join_menu = $JoinMenu
@onready var death_menu = get_node("JoinLobby/deathmenu")
@onready var address_entry = $JoinMenu/JoinMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var main_menu = $MainMenu
@onready var background = $BGImage
@onready var options_menu = $Options
@onready var op = $Options/OptionsMenu
@onready var op_control = $Options/ControlsMenu
@onready var op_key = $Options/KeySelectMenu
@onready var exit = $Exit

@onready var keybindings = [
	$Options/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Forward/Label/Keybindings,
	$Options/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Backward/Label/Keybindings,
	$Options/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Left/Label/Keybindings,
	$Options/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Right/Label/Keybindings,
	$Options/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Jump/Label/Keybindings,
	$Options/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Crouch/Label/Keybindings,
	$Options/ControlsMenu/MarginContainer/VBoxContainer/Label/VideoMarginContainer2/VBoxContainer/Sprint/Label/Keybindings,
	$Options/ControlsMenu/MarginContainer/VBoxContainer/Label/MarginContainer/VBoxContainer/Pause/Label/Keybindings,
	$Options/ControlsMenu/MarginContainer/VBoxContainer/Label/MarginContainer/VBoxContainer/Console/Label/Keybindings
]

@onready var mainmenumusic = $"Sounds and Songs/MainMenuMusic"
@onready var buttonsound = $"Sounds and Songs/ButtonSound"
@onready var buttonbacksound = $"Sounds and Songs/ButtonBackSound"

const Player = preload("res://scenes/misc/player.tscn")
const PORT = 6969
var enet_peer = ENetMultiplayerPeer.new()
var upnp = null

#func _unhandled_input(event):
#	if Input.is_action_just_pressed("quit"):
#		get_tree().quit()

func _ready():
	discord_presence()
	game_menu.disconnect_player.connect(_disconnect_player)
	game_menu.on_host_disconnect.connect(_on_host_disconnect)
	
	for keybinding in keybindings:
		keybinding.button_keybind.connect(_button_keybind)
		keybinding.button_keybind_off.connect(_button_keybind_off)
	
	join_menu.hide()
	options_menu.hide()
	exit.hide()
	main_menu.show()
	background.show()

#func connect_death_menu():
	#death_menu.disconnect_player.connect(_disconnect_player)
	#death_menu.on_host_disconnect.connect(_on_host_disconnect)
	#pass

func discord_presence():
	discord_sdk.app_id = 1165719657815220296 # Application ID
	discord_sdk.details = "In The Main Menu"
	#discord_sdk.state = "Yes, I'm making a game in Godot."
	
	discord_sdk.large_image = "poorjared_singleplayer" # Image key from "Art Assets"
	#discord_sdk.large_image = "placeholder" # Image key from "Art Assets"
	#discord_sdk.large_image_text = "YOOO! Wait, you saw this?"
	#discord_sdk.small_image = "placeholder_small" # Image key from "Art Assets"
	#discord_sdk.small_image_text = "Among us???"
	
	discord_sdk.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
	# discord_sdk.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00 remaining"
	
	discord_sdk.refresh() # Always refresh after changing the values!

func _on_host_button_pressed():
	buttonsound.play()
	mainmenumusic.stop()
	join_menu.hide()
	main_menu.hide()
	background.hide()
	game_menu.joinlobby = false
	emit_signal("player_created")
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player) # Adds player on connect
	multiplayer.peer_disconnected.connect(remove_player) # Remove the player if they leave
	
	add_player(multiplayer.get_unique_id())
	
	upnp_setup()
	
	await get_tree().create_timer(0.00001).timeout
	game_menu.singleplayer = false
	discord_sdk.details = "Playing Multiplayer"
	discord_sdk.large_image = "poorjared_multiplayer"
	discord_sdk.refresh()
	
	#connect_death_menu()

func _on_join_button_pressed():
	buttonsound.play()
	mainmenumusic.stop()
	join_menu.hide()
	main_menu.hide()
	background.hide()
	game_menu.joinlobby = false
	emit_signal("player_created")
	
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	await get_tree().create_timer(0.00001).timeout
	game_menu.singleplayer = false
	discord_sdk.details = "Playing Multiplayer"
	discord_sdk.large_image = "poorjared_multiplayer"
	discord_sdk.refresh()
	
	#connect_death_menu()

func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	player.add_to_group("players") # Add player to group

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func _disconnect_player(peer_id):
	# Close the connection
	if multiplayer.is_server():
		# Notify all clients to go back
		if game_menu.singleplayer:
			get_tree().paused = false
		else:
			rpc("change_scene_of_all_the_clients")
		
		get_tree().change_scene_to_file("res://scenes/test.tscn")
		
		# If UPnP is set up, remove all players and delete the port mapping
		for player in get_children():
				if player.is_in_group("players"):
					player.queue_free()
		if upnp:
			upnp.delete_port_mapping(PORT)
			upnp = null
		
		# Close the server
		if enet_peer:
			enet_peer.close()
			enet_peer = ENetMultiplayerPeer.new()
		
		# Ensure that the multiplayer object is initialized
		if multiplayer:
			# Reset the multiplayer peer to null
			multiplayer.multiplayer_peer = null
	else:
		# If it's a client, disconnect from the server
		remove_player(peer_id)
		enet_peer.disconnect_peer(multiplayer.get_unique_id(), true)
		await get_tree().create_timer(2).timeout # --------------------------------------------------------
		get_tree().change_scene_to_file("res://scenes/test.tscn")
		print($"../")
	
	# Reset the game menu state
	game_menu.joinlobby = true
	game_menu.singleplayer = false
	discord_sdk.details = "In The Main Menu"
	discord_sdk.large_image = "poorjared_singleplayer"
	discord_sdk.refresh()

@rpc ("any_peer", "call_remote") func change_scene_of_all_the_clients():
	enet_peer.disconnect_peer(multiplayer.get_unique_id(), true)
	get_tree().change_scene_to_file("res://scenes/test.tscn")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_host_disconnect():
	if multiplayer.is_server() && game_menu.singleplayer == false:
		# Notify all clients to go back
		rpc("change_scene_of_all_the_clients")
		
		get_tree().quit() # Exit the game
	else:
		get_tree().quit() # Exit the game

func upnp_setup():
	upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	#assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		#"UPNP Discover Failed! Error %s" % discover_result)
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		var discover_error = "Yeahhhh... don't know how to fix your problem. Good luck brotha. Probably some unknown error. I don't know..."
		if discover_result == UPNP.UPNP_RESULT_NOT_AUTHORIZED: discover_error = "Game is not authorized to use commands on the UPNP Device. May be caused when the user disabled UPNP on their router."
		if discover_result == UPNP.UPNP_RESULT_PORT_MAPPING_NOT_FOUND: discover_error = "No port mapping was found for the given port, protocol combination on the given UPNP Device."
		if discover_result == UPNP.UPNP_RESULT_INCONSISTENT_PARAMETERS: discover_error = "Inconsistent parameters."
		if discover_result == UPNP.UPNP_RESULT_NO_SUCH_ENTRY_IN_ARRAY: discover_error = "No such entry in array. May be caused if a given port, protocol combination is not found on an UPNP Device."
		if discover_result == UPNP.UPNP_RESULT_ACTION_FAILED: discover_error = "The action failed."
		if discover_result == UPNP.UPNP_RESULT_SRC_IP_WILDCARD_NOT_PERMITTED: discover_error = "The UPNP Device does not allow wildcard values for the source IP address."
		if discover_result == UPNP.UPNP_RESULT_EXT_PORT_WILDCARD_NOT_PERMITTED: discover_error = "The UPNP Device does not allow wildcard values for the external port."
		if discover_result == UPNP.UPNP_RESULT_INT_PORT_WILDCARD_NOT_PERMITTED: discover_error = "The UPNP Device does not allow wildcard values for the internal port."
		if discover_result == UPNP.UPNP_RESULT_REMOTE_HOST_MUST_BE_WILDCARD: discover_error = "The remote host value must be a wildcard."
		if discover_result == UPNP.UPNP_RESULT_EXT_PORT_MUST_BE_WILDCARD: discover_error = "The external port value must be a wildcard."
		if discover_result == UPNP.UPNP_RESULT_NO_PORT_MAPS_AVAILABLE: discover_error = "No port maps are available. May also be caused if port mapping functionality is not available."
		if discover_result == UPNP.UPNP_RESULT_CONFLICT_WITH_OTHER_MECHANISM: discover_error = "Conflict with other mechanism. May be caused if a port mapping conflicts with an existing one."
		if discover_result == UPNP.UPNP_RESULT_CONFLICT_WITH_OTHER_MAPPING: discover_error = "Conflict with an existing port mapping."
		if discover_result == UPNP.UPNP_RESULT_SAME_PORT_VALUES_REQUIRED: discover_error = "External and internal port values must be the same."
		if discover_result == UPNP.UPNP_RESULT_ONLY_PERMANENT_LEASE_SUPPORTED: discover_error = "Only permanent leases are supported."
		if discover_result == UPNP.UPNP_RESULT_INVALID_GATEWAY: discover_error = "Invalid gateway."
		if discover_result == UPNP.UPNP_RESULT_INVALID_PORT: discover_error = "Invalid port."
		if discover_result == UPNP.UPNP_RESULT_INVALID_PROTOCOL: discover_error = "Invalid protocol."
		if discover_result == UPNP.UPNP_RESULT_INVALID_DURATION: discover_error = "Invalid duration."
		if discover_result == UPNP.UPNP_RESULT_INVALID_ARGS: discover_error = "Invalid arguments."
		if discover_result == UPNP.UPNP_RESULT_INVALID_RESPONSE: discover_error = "Invalid response."
		if discover_result == UPNP.UPNP_RESULT_INVALID_PARAM: discover_error = "Invalid response."
		if discover_result == UPNP.UPNP_RESULT_HTTP_ERROR: discover_error = "HTTP error."
		if discover_result == UPNP.UPNP_RESULT_SOCKET_ERROR: discover_error = "Socket error."
		if discover_result == UPNP.UPNP_RESULT_MEM_ALLOC_ERROR: discover_error = "Error allocating memory."
		if discover_result == UPNP.UPNP_RESULT_NO_GATEWAY: discover_error = "No gateway available."
		if discover_result == UPNP.UPNP_RESULT_NO_DEVICES: discover_error = "No devices available."
		if discover_result == UPNP.UPNP_RESULT_UNKNOWN_ERROR: discover_error = "Unknown error."
		OS.alert("UPNP Discover Failed! %s" % discover_error, 'UPNP Error')

	#assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		#"UPNP Invalid Gateway!")
	if upnp.get_gateway() == null:
		OS.alert("UPNP Invalid Gateway! If your router has UPNP and has this error, try manually port forwarding in the router.", 'UPNP Error')
	
	var map_result = upnp.add_port_mapping(PORT)
	#assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		#"UPNP Port Mapping Failed! Error %s" % map_result)
	
	#if map_result != UPNP.UPNP_RESULT_SUCCESS:
		#OS.alert("UPNP Port Mapping Failed! Error %s" % map_result, 'UPNP Error')
	
	#print("Success! Join Address: %s" % upnp.query_external_address())
	if upnp.query_external_address() == "":
		OS.alert("There was a problem while getting the server external address, make sure to fix all of the errors you've encountered, if any. You can also just ignore this and find your external address, but this also may or may not lead to connection problems for connected players. This problem is common on Huawei and TP-Link routers", "UPNP Setup Warning")
		OS.alert("It wasn't successful, but hey, here's the join address, maybe it'll work anyway: %s" % upnp.query_external_address(), 'Kinda Successful UPNP Setup')
	else:
		OS.alert("Success! Join Address: %s" % upnp.query_external_address(), 'Successful UPNP Setup')


func _on_single_button_pressed():
	buttonsound.play()
	mainmenumusic.stop()
	join_menu.hide()
	main_menu.hide()
	background.hide()
	game_menu.joinlobby = false
	emit_signal("player_created")
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	add_player(multiplayer.get_unique_id())
	
	await get_tree().create_timer(0.00001).timeout
	game_menu.singleplayer = true
	discord_sdk.details = "Playing Singleplayer"
	discord_sdk.large_image = "poorjared_yee"
	discord_sdk.refresh()
	
	#connect_death_menu()

func _on_multi_button_pressed():
	buttonsound.play()
	join_menu.show()
	main_menu.hide()

func _on_credits_button_pressed():
	buttonsound.play()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/menus/credits.tscn")

func _input(event):
	if exit.visible:
		if event.is_action_pressed("pause"):
			buttonbacksound.play()
			await get_tree().create_timer(0.3).timeout
			get_tree().quit()
	
	if main_menu.visible and !exit.visible:
		if event.is_action_pressed("pause"):
			buttonbacksound.play()
			main_menu.hide()
			exit.show()
	
	if join_menu.visible:
		if event.is_action_pressed("pause"):
			buttonbacksound.play()
			join_menu.hide()
			main_menu.show()
			exit.hide()
	
	if options_menu.visible:
		if event.is_action_pressed("pause"):
			if op.visible:
				buttonbacksound.play()
				options_menu.hide()
				main_menu.show()
				exit.hide()
			if op_control and !op_key.visible:
				buttonbacksound.play()
				op.show()
				op_control.hide()

func _on_options_button_pressed():
	buttonsound.play()
	join_menu.hide()
	main_menu.hide()
	options_menu.show()
	op.show()

func _on_back_button_options_pressed():
	buttonbacksound.play()
	options_menu.hide()
	op.hide()
	main_menu.show()
	exit.hide()

func _on_controls_button_pressed():
	buttonsound.play()
	op_control.show()
	op.hide()

func _on_back_button_controls_options_pressed():
	buttonbacksound.play()
	op_control.hide()
	op.show()

func _button_keybind():
	buttonsound.play()
	op_key.show()

func _button_keybind_off():
	buttonbacksound.play() # Maybe a key sound?
	op_key.hide()

func _on_back_button_pressed():
	buttonbacksound.play()
	join_menu.hide()
	main_menu.show()
	exit.hide()

func _on_leave_button_pressed():
	buttonbacksound.play()
	main_menu.hide()
	exit.show()

func _on_no_button_pressed():
	buttonsound.play()
	main_menu.show()
	exit.hide()

func _on_yes_button_pressed():
	buttonbacksound.play()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()
