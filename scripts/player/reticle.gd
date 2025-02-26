extends CenterContainer

@export var color : Color = Color.RED

@export var dot_radius : float = 2.0

@export var dynamic_reticle : bool = false
@export var reticle_lines : Array[Line2D]
@export var reticle_speed : float = 2.0
@export var reticle_distance : float = 1.0
@export var player_controller : CharacterBody3D

func _ready():
	queue_redraw()
	change_reticle_color()

func _process(delta):
	if dynamic_reticle == true:
		adjust_reticle_lines()
	else:
		for lines in reticle_lines:
			lines.position = Vector2(0,0)
#		reticle_lines[0].position = Vector2(0,0)
#		reticle_lines[1].position = Vector2(0,0)
#		reticle_lines[2].position = Vector2(0,0)
#		reticle_lines[3].position = Vector2(0,0)

func _draw():
	draw_circle(Vector2(0,0),dot_radius,color)

func change_reticle_color():
	for lines in reticle_lines:
		lines.default_color = color

func adjust_reticle_lines():
	var vel = player_controller.get_real_velocity()
	var origin = Vector3(0,0,0)
	var pos = Vector2(0,0)
	var speed = origin.distance_to(vel)
	#Adjust reticle line position
	reticle_lines[0].position = lerp(reticle_lines[0].position, pos + Vector2(0, -speed + reticle_distance), reticle_speed) # Top
	reticle_lines[1].position = lerp(reticle_lines[1].position, pos + Vector2(speed + reticle_distance, 0), reticle_speed) # Right
	reticle_lines[2].position = lerp(reticle_lines[2].position, pos + Vector2(0, speed + reticle_distance), reticle_speed) # Bottom
	reticle_lines[3].position = lerp(reticle_lines[3].position, pos + Vector2(-speed + reticle_distance, 0), reticle_speed) # Left
