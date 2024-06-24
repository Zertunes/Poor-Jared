extends Camera3D

@onready var view_model_rig = $ViewModelRig
@onready var player = $"../../../../../../.."
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
	var velocity_clamped = clamp(player.velocity.length(), 0.5, player.top_speed_air * 2)
	#print("a" + str(player.velocity.length()))
	#print("b" + str(player.top_speed_air))
	var position_multiplier = default_position_multiplier * -0.01
	var target_position = default_position + position_multiplier * velocity_clamped
	if player.run == true and player.crouching_collision.disabled == true:
		target_position = default_position + (position_multiplier * velocity_clamped) * 3
	else:
		target_position = default_position + position_multiplier * velocity_clamped
	view_model_rig.position.y = lerp(view_model_rig.position.y, target_position, player.edelta * 8.0)
