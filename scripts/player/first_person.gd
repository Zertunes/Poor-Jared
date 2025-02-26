extends Node

@export var PLAYER: CharacterBody3D
@export var HEALTH: Node
@export var HUD: Node
@export var MOVEMENT: Node
@export var TrdP: Node
@onready var GAMEMENU = get_parent().get_parent().get_parent().get_node("GameMenu")

@export var head: Node3D
@export var body: Node3D
@export var tilt: Node3D
@export var camera: Camera3D
@export var view_model_viewport: SubViewport
@export var view_model_camera: Camera3D
@onready var view_model_rig = $"../Body/Head/Tilt/FPCamera/SubViewportContainer/SubViewport/ViewModelCamera/ViewModelRig"
@onready var view_model_rig_anim = $"../Body/Head/Tilt/FPCamera/SubViewportContainer/SubViewport/ViewModelCamera/ViewModelRig/AnimationPlayer"
var camera_target_position : Vector3 = Vector3()
var camera_coefficient: float = 1.0
var camera_behavior_time_in_air: float = 0.0
var camera_current_interpolated_transform : Transform3D
var bobbing_frequency_end = 4

# ==================== [Camera] ====================
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("pause"):
		if HEALTH.dead == true:
			print("a")
			if GAMEMENU.paused == true:
				HUD.deathmenu.background.hide()
				HUD.deathmenu.death_menu.hide()
			else:
				HUD.deathmenu.background.show()
				HUD.deathmenu.death_menu.show()
	
	handle_camera_mouse_movement(event)

func handle_camera_mouse_movement(event):
	# Can't look around when paused.
	if GAMEMENU.paused == true or HEALTH.dead == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
	#if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			#head.rotate_y(-event.relative.x * mouse_sens)
			#camera.rotate_x(-event.relative.y * mouse_sens)
			#camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			body.rotate_y(-event.relative.x * PLAYER.mouse_sens)
			head.rotate_x(-event.relative.y * PLAYER.mouse_sens)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			TrdP.mesh.rotation.y = body.rotation.y + deg_to_rad(180)
			view_model_camera.swing(Vector2(event.relative.x,event.relative.y))
	
	camera.set_as_top_level(true)
	camera_target_position = camera.global_transform.origin
func manage_camera_smoothing(delta):
	camera_current_interpolated_transform = head.get_global_transform()
	camera_target_position = lerp(camera_target_position, camera_current_interpolated_transform.origin, delta * MOVEMENT.top_speed * MOVEMENT.stairs_feeling_coefficient * camera_coefficient)
	var camera_target_position_y = lerp(camera_target_position, camera_current_interpolated_transform.origin + (tilt.position*bobbing_frequency_end), delta * MOVEMENT.top_speed * MOVEMENT.stairs_feeling_coefficient * camera_coefficient)
	camera.position.x = camera_current_interpolated_transform.origin.x + tilt.position.x
	camera.position.z = camera_current_interpolated_transform.origin.z + tilt.position.x
	
	if PLAYER.is_on_floor():
		camera_behavior_time_in_air = 0.0
		camera_coefficient = 1.0
		camera.position.y = camera_target_position_y.y
	else:
		camera_behavior_time_in_air += delta
		if camera_behavior_time_in_air > 1.0:
			camera_coefficient += delta
			camera_coefficient = clamp(camera_coefficient, 2.0, 4.0)
		else: 
			camera_coefficient = 2.0
			
		camera.position.y = camera_target_position_y.y
		
	camera.rotation.z = tilt.rotation.z
	camera.rotation.x = head.rotation.x
	camera.rotation.y = body.rotation.y # + body.global_transform.basis.get_euler().y
