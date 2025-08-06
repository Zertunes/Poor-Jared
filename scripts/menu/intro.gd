extends Node2D

@onready var mainmenu = preload("res://scenes/world/city/city.tscn")
@onready var test = preload("res://scenes/world/test/test.tscn")

func _input(event):
	if event is InputEventKey:
		# Test place
		if Input.is_key_pressed(KEY_CTRL):
			if Input.is_key_pressed(KEY_TAB):
				get_tree().change_scene_to_packed(test)
		else:
			skip()
	if event is InputEventMouseButton:
		skip()
	
	## test place
	#if event is InputEventKey and event.pressed:
		#var key_sequence: String = ""
		#var key = event.as_text().to_lower()
		#key_sequence += key
		#if key_sequence.length() > 7:
			#key_sequence = key_sequence.substr(key_sequence.length() - 7, 7)
		#if key_sequence == "amongus":
			#get_tree().change_scene_to_file("res://scenes/test/test.tscn")

func _ready():
	$VideoStreamPlayer.play()

func _physics_process(delta):
	await get_tree().create_timer(0.1).timeout
	if !$VideoStreamPlayer.is_playing():
		skip()

func skip():
	$VideoStreamPlayer.hide()
	#await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_packed(mainmenu)
