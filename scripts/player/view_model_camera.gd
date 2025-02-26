extends Camera3D

@onready var view_model_rig = $ViewModelRig
@export var PLAYER: CharacterBody3D
@export var STAMINA: Node
@export var MOVEMENT: Node
var use = true
var default_position = 0
var default_position_multiplier = 0.5

func _ready():
	pass

func _process(delta):
	if not is_multiplayer_authority(): return
	view_model_rig.position.x = lerp(view_model_rig.position.x,0.0,delta*5)
	view_model_rig.position.y = lerp(view_model_rig.position.y,0.0,delta*5)
	walking()

func swing(amount): # Used on the player.gd mouse input
	view_model_rig.position.x -= amount.x*0.00005
	view_model_rig.position.y += amount.y*0.00005

func walking():
	var velocity_clamped = clamp(PLAYER.velocity.length(), 0.5, MOVEMENT.top_speed_air * 2)
	#print("a" + str(player.velocity.length()))
	#print("b" + str(player.top_speed_air))
	var position_multiplier = default_position_multiplier * -0.01
	var target_position = default_position + position_multiplier * velocity_clamped
	if STAMINA.run == true and MOVEMENT.crouching_collision.disabled == true:
		target_position = default_position + (position_multiplier * velocity_clamped) * 3
	else:
		target_position = default_position + position_multiplier * velocity_clamped
	view_model_rig.position.y = lerp(view_model_rig.position.y, target_position, PLAYER.edelta * 8.0)
