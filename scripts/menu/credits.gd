extends Node2D

@onready var text = $CreditsText
@onready var opacity = $Opacity
@onready var t = 0.0
@onready var t2 = 0.0

func _input(event):
	if event is InputEventKey and event.pressed:
		get_tree().change_scene_to_file("res://scenes/test.tscn")
	if event is InputEventMouseButton:
		get_tree().change_scene_to_file("res://scenes/test.tscn")

func _ready():
	$MainMenuMusic.play(252.0)
	#$MainMenuMusic.seek(252.0) I can use this later maybe?
	#text.position = Vector2(42, 568)
	#text.position = Vector2(42, -1000)

func _physics_process(delta):
	t += delta * 0.03
	#text.position = Vector2(42, 568).lerp(Vector2(42, -1500), t)
	text.position = Vector2(42, 440).lerp(Vector2(42, -1300), t)
	
	if t >= 1.0:
		get_tree().change_scene_to_file("res://scenes/test.tscn")
	
	if t >= 0.75:
		t2 += delta * 0.5
		opacity.modulate = Color(0, 0, 0, 1).lerp(Color(0, 0, 0, 0), t2)
