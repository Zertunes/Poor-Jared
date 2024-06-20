extends Camera3D

@onready var view_model_rig = $ViewModelRig
var use = true

func _ready():
	pass

func _process(delta):
	if not is_multiplayer_authority(): return
	view_model_rig.position.x = lerp(view_model_rig.position.x,0.0,delta*5)
	view_model_rig.position.y = lerp(view_model_rig.position.y,0.0,delta*5)

func swing(amount):
	view_model_rig.position.x -= amount.x*0.00005
	view_model_rig.position.y += amount.y*0.00005
