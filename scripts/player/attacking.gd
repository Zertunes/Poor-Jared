extends Node

@onready var PLAYER: CharacterBody3D = get_parent()
@export var SOUNDS: Node
@export var TrdP: Node
@export var FstP: Node
@export var MOVEMENT: Node
@onready var GAMEMENU = get_parent().get_parent().get_parent().get_node("GameMenu")

@onready var attacking: bool = false
@export var attack_ik_timer: Timer
@onready var attack_ik_lerp: float = 0.0
@onready var looking_ik_lerp: float = 1.0
@export var punch_ray: RayCast3D

func player_attacking_func():
	if GAMEMENU.singleplayer == false:
		var collider = punch_ray.get_collider()
		if punch_ray.is_colliding():
			print(collider)
			if not (collider is StaticBody3D):
				if collider.has_method("on_hit_while_blocking"): # Check if the collider is defending
					collider.on_hit_while_blocking()
				else:
					collider.MULTIPLAYER.receive_damage.rpc_id(collider.get_multiplayer_authority())
				print(collider.get_multiplayer_authority())

func player_attacking():
	if MOVEMENT.standing_collision.disabled == true:
		if GAMEMENU.paused == true:
			attacking = false
			return
		# Attacking Crouched
		if Input.is_action_just_pressed("attack") && PLAYER.is_on_floor() && !TrdP.landing_animation_on_fall && attacking == false:
			TrdP.mesh_3rd_animation.set("parameters/attack_event_crouch/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			on_attack()
		
		TrdP.mesh_3rd_animation.set("parameters/attack_event/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	else:
		if GAMEMENU.paused == true:
			attacking = false
			return
		# Attacking Normal
		if Input.is_action_just_pressed("attack") && PLAYER.is_on_floor() && !TrdP.landing_animation_on_fall && attacking == false:
			TrdP.mesh_3rd_animation.set("parameters/attack_event/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			on_attack()
		
		TrdP.mesh_3rd_animation.set("parameters/attack_event_crouch/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)

func player_attacking_ik(play: bool):
	if play == false:
		attack_ik_lerp = 0.0
		looking_ik_lerp = 1.0
	else:
		attack_ik_lerp = 1.0
		looking_ik_lerp = 0.0
	# Body IK
	TrdP.rotate_x_attack_animation_ik.interpolation = lerp(TrdP.rotate_x_attack_animation_ik.interpolation, attack_ik_lerp, PLAYER.edelta * 30)
	if TrdP.rotate_x_attack_animation_ik.interpolation == 0.0:
		TrdP.rotate_x_attack_animation_ik.stop()
	else:
		TrdP.rotate_x_attack_animation_ik.start()
	# Head IK
	TrdP.rotate_x_looking_animation_ik.interpolation = lerp(TrdP.rotate_x_looking_animation_ik.interpolation, looking_ik_lerp, PLAYER.edelta * 30)
	if TrdP.rotate_x_looking_animation_ik.interpolation == 0.0:
		TrdP.rotate_x_looking_animation_ik.stop()
	else:
		TrdP.rotate_x_looking_animation_ik.start()

func _on_attack_ik_timer_timeout():
	attacking = false

func on_attack():
	FstP.view_model_rig_anim.play("Attack")
	attacking = true
	attack_ik_timer.start()
	player_attacking_func()
	SOUNDS.punch.play()
