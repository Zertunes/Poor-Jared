extends Node

@export var PLAYER: CharacterBody3D
@export var HEALTH: Node
@export var MOVEMENT: Node
@export var FstP: Node
@export var HUD: Control
@onready var GAMEMENU = get_parent().get_parent().get_parent().get_node("GameMenu")

@onready var camera: Camera3D = FstP.camera
@export var camera_third: Camera3D
@export var third_person_body: Node3D
@export var mesh: Node3D
@onready var mesh_skin = $"../Skin/Armature/Skeleton3D/Player"
@onready var mesh_3rd_animation_player = $"../Skin/AnimationPlayer"
@onready var mesh_3rd_animation = $"../Skin/AnimationTree"
@onready var rotate_x_looking_animation_ik: SkeletonIK3D = $"../Skin/Armature/Skeleton3D/HeadIK"
@onready var rotate_x_attack_animation_ik: SkeletonIK3D = $"../Skin/Armature/Skeleton3D/HandAttackIK"
@onready var rotate_x_looking_animation_target: Marker3D = $"../Skin/Marker3DHeadTarget"
@onready var rotate_x_attack_animation_target: Marker3D = $"../Skin/Marker3DHandAttackTarget"

var landing_animation_on_fall = false
var perspective: int = 1


func perspective_switch():
	if GlobalDebug.noclip == false:
		if HEALTH.dead == false:
			if Input.is_action_just_pressed("perspective"):
				perspective += 1
		else:
			perspective = 1
	else:
		perspective = 1
	
	
	if perspective > 3:
		perspective = 1
	
	if perspective != 1:
		if perspective == 2:
			third_person_body.rotation.x = -camera.rotation.x
			third_person_body.rotation.y = camera.rotation.y + deg_to_rad(180)
		else:
			third_person_body.rotation = camera.rotation
		camera_third.fov = camera.fov
		if MOVEMENT.standing_collision.disabled == true:
			third_person_body.position.y = lerp(third_person_body.position.y, 1.9 + MOVEMENT.crouching_depth, PLAYER.edelta * MOVEMENT.lerp_speed)
		else:
			third_person_body.position.y = lerp(third_person_body.position.y, 1.9, PLAYER.edelta * MOVEMENT.lerp_speed)
	
	if perspective == 1:
		FstP.view_model_camera.visible = true
		camera.current = true
		camera_third.current = false
		#mesh.show()
		mesh_skin.set_cast_shadows_setting(3)
		HUD.reticle.visible = true
	elif perspective == 2:
		FstP.view_model_camera.visible = false
		camera.current = false
		camera_third.current = true
		#mesh.show()
		mesh_skin.set_cast_shadows_setting(1)
		HUD.reticle.visible = false
	elif perspective == 3:
		FstP.view_model_camera.visible = false
		camera.current = false
		camera_third.current = true
		#mesh.show()
		mesh_skin.set_cast_shadows_setting(1)
		HUD.reticle.visible = false

func _handle_3rd_person_animations(input_direction, delta):
	# Old Code for the old animation tree state machine
	#mesh_3rd_animation.set("parameters/conditions/idle", standing_collision.disabled == false && input_direction == Vector2.ZERO && is_on_floor())
	#mesh_3rd_animation.set("parameters/conditions/moving_forward", standing_collision.disabled == false && input_direction.y == -1 && is_on_floor())
	#mesh_3rd_animation.set("parameters/conditions/moving_backward", standing_collision.disabled == false && input_direction.y == 1 && is_on_floor())
	#mesh_3rd_animation.set("parameters/conditions/moving_left", standing_collision.disabled == false && input_direction.x == -1 && is_on_floor())
	#mesh_3rd_animation.set("parameters/conditions/moving_right", standing_collision.disabled == false && input_direction.x == 1 && is_on_floor())
	#mesh_3rd_animation.set("parameters/conditions/crouch", standing_collision.disabled == true && is_on_floor())
	#mesh_3rd_animation.set("parameters/conditions/jump", !is_on_floor())
	
	if !PLAYER.is_on_floor():
		landing_animation_on_fall = true
	
	# If game is paused, don't animate
	if GAMEMENU.paused == true:
		if MOVEMENT.standing_collision.disabled == true:
			# Crouch
			if PLAYER.is_on_floor():
				mesh_3rd_animation.set("parameters/crouched/blend_position", lerp(mesh_3rd_animation.get("parameters/crouched/blend_position"), Vector2(0, 0), delta * MOVEMENT.acceleration_ground))
		else:
			# Normal
			if PLAYER.is_on_floor():
				mesh_3rd_animation.set("parameters/walking/blend_position", lerp(mesh_3rd_animation.get("parameters/walking/blend_position"), Vector2(0, 0), delta * MOVEMENT.acceleration_ground))
			return # don't run the code below
	
	# Handles the walking and crouching animations as well for the crouching animation itself and on falling
	if MOVEMENT.standing_collision.disabled == true:
		# Crouch event on crouched walking animation
		mesh_3rd_animation.set("parameters/crouch_event/blend_amount", lerp(mesh_3rd_animation.get("parameters/crouch_event/blend_amount"), 1.0, delta * MOVEMENT.acceleration_ground))
		if PLAYER.is_on_floor() && ((( PLAYER.velocity * Vector3(0, 0, 1) ).length()) > 0.5 || (( PLAYER.velocity * Vector3(1, 0, 0) ).length()) > 0.5):
			mesh_3rd_animation.set("parameters/crouched/blend_position", lerp(mesh_3rd_animation.get("parameters/crouched/blend_position"), input_direction, delta * MOVEMENT.acceleration_ground))
		else:
			mesh_3rd_animation.set("parameters/crouched/blend_position", lerp(mesh_3rd_animation.get("parameters/crouched/blend_position"), Vector2(0, 0), delta * 20))
	else:
		# Crouch event on normal walking animation
		mesh_3rd_animation.set("parameters/crouch_event/blend_amount", lerp(mesh_3rd_animation.get("parameters/crouch_event/blend_amount"), 0.0, delta * MOVEMENT.acceleration_ground))
		if PLAYER.is_on_floor() && ((( PLAYER.velocity * Vector3(0, 0, 1) ).length()) > 0.5 || (( PLAYER.velocity * Vector3(1, 0, 0) ).length()) > 0.5):
			mesh_3rd_animation.set("parameters/walking/blend_position", lerp(mesh_3rd_animation.get("parameters/walking/blend_position"), input_direction, delta * MOVEMENT.acceleration_ground))
		else:
			mesh_3rd_animation.set("parameters/walking/blend_position", lerp(mesh_3rd_animation.get("parameters/walking/blend_position"), Vector2(0, 0), delta * 20))
	
	# Jumping animation is at "ground_move(delta)"
	# Attacking is at "player_attacking()"
	# Landing animation is at "handle_gravity(delta)"
func _handle_3rd_person_head_IK():
	rotate_x_looking_animation_target.rotation.x = -camera.rotation.x
func _handle_3rd_person_hand_attack_IK():
	rotate_x_attack_animation_target.rotation.x = -camera.rotation.x
