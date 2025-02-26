extends Node2D

@onready var text = $CreditsText
@onready var textrich = $CreditsTextRich
@onready var opacity = $Opacity
@onready var t = 0.0
@onready var t2 = 0.0
@onready var mainmenu = "res://scenes/world/city/city.tscn"

func _input(event):
	if event is InputEventKey and event.pressed:
		get_tree().change_scene_to_file(mainmenu)
	if event is InputEventMouseButton:
		get_tree().change_scene_to_file(mainmenu)

func _ready():
	$MainMenuMusic.play(252.0)
	#$MainMenuMusic.seek(252.0) I can use this later maybe?
	#text.position = Vector2(42, 568)
	#text.position = Vector2(42, -1000)

func _physics_process(delta):
	t += delta * 0.03
	#text.position = Vector2(42, 568).lerp(Vector2(42, -1500), t)
	text.position = Vector2(42, 440).lerp(Vector2(42, -1300), t)
	textrich.position = Vector2(142, 540).lerp(Vector2(142, -1200), t)
	
	if t >= 0.9605:
		get_tree().change_scene_to_file(mainmenu)
	
	if t >= 0.72:
		t2 += delta * 0.5
		opacity.modulate = Color(0, 0, 0, 1).lerp(Color(0, 0, 0, 0), t2)
