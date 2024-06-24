extends CharacterBody3D
#Thanks to EthanTheEnigma for the movement code inpired by the Source Engine. https://www.youtube.com/watch?v=45ERGbDV050&ab_channel=EthanTheEnigma (Code reorginazed, rewriten, edited and changed)

# Game Menu (I call it the Pause Menu)
@onready var game_menu = get_parent().get_parent().get_node("GameMenu") #$GameMenu

# Player nodes
@onready var HUD = $Control
@onready var body = $Body
@onready var head = $Body/Head
@onready var tilt = $Body/Head/Tilt
@onready var camera: Camera3D = $Body/Head/Tilt/FPCamera
@onready var third_person_body = $TPBody
@onready var camera_third: Camera3D = $TPBody/TPCamera
@onready var view_model_viewport = $Body/Head/Tilt/FPCamera/SubViewportContainer/SubViewport
@onready var view_model_camera = $Body/Head/Tilt/FPCamera/SubViewportContainer/SubViewport/ViewModelCamera
@onready var view_model_rig = $Body/Head/Tilt/FPCamera/SubViewportContainer/SubViewport/ViewModelCamera/ViewModelRig
@onready var view_model_rig_anim = $Body/Head/Tilt/FPCamera/SubViewportContainer/SubViewport/ViewModelCamera/ViewModelRig/AnimationPlayer
@onready var mesh = $Skin #$MeshInstance3D
@onready var mesh_skin = $Skin/Armature/Skeleton3D/Player
@onready var mesh_3rd_animation_player = $Skin/AnimationPlayer
@onready var mesh_3rd_animation = $Skin/AnimationTree
@onready var walking_lerp = Vector2.ZERO
@onready var standing_collision = $Standing_Collision
@onready var crouching_collision = $Crouching_Collision
@onready var ray_cast_3d = $RayCast3D
@onready var speed_label: Label = $Control/Speed
@onready var fps_label: Label = $Control/FPS
#@onready var stamina_label: Label = $Control/Stamina
@onready var stamina_bar: TextureProgressBar = $Control/StaminaBar
@onready var chromatic_abberation: ColorRect = $Body/Head/Tilt/ChromaticAbberation
@onready var shader_material: ShaderMaterial
@onready var shader_layer: CanvasLayer = $Body/Head/Tilt/ShaderLayer
@onready var rotate_x_looking_animation_ik: SkeletonIK3D = $Skin/Armature/Skeleton3D/HeadIK
@onready var rotate_x_attack_animation_ik: SkeletonIK3D = $Skin/Armature/Skeleton3D/HandAttackIK
@onready var rotate_x_looking_animation_target: Marker3D = $Skin/Marker3DHeadTarget
@onready var rotate_x_attack_animation_target: Marker3D = $Skin/Marker3DHandAttackTarget
@onready var attacking: bool = false
@onready var attack_ik_timer: Timer = $AttackIKTimer
@onready var attack_ik_lerp: float = 0.0
@onready var looking_ik_lerp: float = 1.0
@onready var reticle = $Control/Reticle
@onready var deathmenu = {
	"death_menu": $deathmenu/DeathMenu,
	"background": $deathmenu/DeathMenu/Background,
}
@onready var punch_ray = $Body/Head/Tilt/FPCamera/punch_ray

@onready var edelta = 0

# View Bobbing
var bobbing_frequency = 2.0
var bobbing_amplifier = 0.08
var time_view_bobbing =  0.0
var bobbing_frequency_end = 4

# FOV
var fov_base = 70
var fov_change = 1.5

# Options for view bobbing, sideways tilt, FOV change and mouse sensitivity
var option_view_bobbing = true
var option_fov_change = true
var option_sideways_tilt = true
var option_chromatic_abberation = true
var mouse_sens = 0.002
var jump_twice = false
var landing_animation_on_fall = false

# Debug
var auto_bunny_hopping: bool = false
var enable_bunny_hopping: bool = false
var disable_run_ticking: bool = false
var noclip: bool = false
var noclip_speed: float = 40.0
var just_start_noclip: bool = true
var perspective: int = 1

# Health
@onready var health = $Health
@onready var ragdoll = preload("res://scenes/misc/ragdoll.tscn")

# --------------[Movement Physics]--------------
# Gravity from project's settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Player controls
var direction_wish_to_go: Vector3 = Vector3.ZERO
var crouching_depth: float = -0.5
var head_end_position : Vector3 = Vector3(0,1.9,0)
var lerp_speed: float = 10
# Ground
var grounded: bool = true
var friction: float = 4 # 4 = ground  0.5 = ice
var linearize_friction_speed_below_this_speed: float = 7 #10
var acceleration_ground: float = 10
# Speed
var speed_changer: float = 3
var top_speed: float = 7 #15
var top_speed_walking: float = 7
var top_speed_crouch: float = top_speed_walking - speed_changer
var top_speed_sprint: float = top_speed_walking + speed_changer
var top_speed_air: float = 2.5 # 15 for quake 2/3, 2.5 for quake 1/source, 0 makes it so you can't strafe (Lower, low speed and strafing. High, high speed and strafing.)
var top_speed_stairs: float = top_speed_walking - 1.5
var air_speed_cap: float = top_speed + speed_changer
# Stairs
var stairs_feeling_coefficient: float = 2.5
var snap: Vector3 = Vector3.ZERO
var gravity_vector: Vector3 = Vector3.ZERO
@onready var head_position: Vector3 = head.position
@onready var body_euler_y = body.global_transform.basis.get_euler().y
var head_offset: Vector3 = Vector3.ZERO
var is_step: bool = false
var wall_margin: float = 0.001
var step_height_default: Vector3 = Vector3(0, 0.6, 0)
var step_max_slope_degree: float = 0.0
var step_check_count: int = 2
var step_check_height: Vector3 = step_height_default / step_check_count
var camera_target_position : Vector3 = Vector3()
var camera_coefficient: float = 1.0
var camera_behavior_time_in_air: float = 0.0
var camera_current_interpolated_transform : Transform3D
# Running/Stamina
var stamina_points: float = 100
var run: bool = false
var run_ticking: bool = false
var stamina_recharge: bool = false
var stamina_loss: float = 1
var stamina_regain: float = 0.5
var sub_time = 5
var time_between_sub = sub_time
var time_between_sub2 = sub_time
# Air
var jump_force: float = 13 #14
var projected_speed: float = 0 # Speed to add and remove then moving on the ground and air (changing this will do no effect, it is calculated on _physics_process)
var acceleration_air: float = 40 #14 # 4 for quake 2/3 40 for quake 1/source

func _enter_tree():
	set_multiplayer_authority(name.to_int())
func _ready():
	loading_hiding(true)

	if not is_multiplayer_authority(): return
	loading_hiding(false)
	
	_stamina_label()
	connect_global_options()
	connect_health_component()

# ==================== [Health] ====================
func connect_health_component():
	health.player_died.connect(_on_player_died)
	health.health_changed.connect(_on_health_changed)
func _on_player_died():
	#print("Player has died")
	#health.do_damage(20)
	deathmenu.background.show()
	deathmenu.death_menu.show()
	mesh.hide()
	view_model_rig.visible = false
	
	$DeathVoice.play()
	
	# Instantiate the ragdoll scene and set its position to the player's current position
	var ragdoll_instance = ragdoll.instantiate()
	ragdoll_instance.global_transform = self.global_transform
	get_parent().add_child(ragdoll_instance)
	
func _on_health_changed(new_health):
	#print("Health changed to: ", new_health)
	pass

# This controls hiding and displaying stuff on start,
# it is awesome for stuff like local client and
# multiplayer client differences.
func loading_hiding(hide: bool): 
	if hide == true: # This is on start, for hiding multiplayer. (Remote)
		# Hides 1st person view model for other players
		view_model_camera.set_cull_mask_value(2, false)
		view_model_rig.visible = false
		# Starts the SkeletonIK3D rotation for the 3rd person head
		rotate_x_looking_animation_ik.start()
		rotate_x_attack_animation_ik.stop()
		# Hides the Stamina bar
		stamina_bar.visible = false
		
		# Hides player GUI so it doesn't multiply on multiplayer
		HUD.hide()
		$Body/Head/Tilt/Vignette.hide()
		
		
		# Hide the death screen
		deathmenu.background.hide()
		deathmenu.death_menu.hide()
	if hide == false: # This is after hiding, to show. (Local)
		# Shows 1st person view model for local player
		view_model_camera.set_cull_mask_value(2, true)
		view_model_rig.visible = true
		# Makes the size of the first person view model the same as the screen (in 1st person)
		view_model_viewport.size = DisplayServer.window_get_size()
		# Makes the camera the current one
		camera.current = true
		# Hides 3rd person character from local player (Doesn't need to be used now because I added perspectives (and there are shadows in first person))
		#mesh.hide()
		# Shows the Stamina bar
		stamina_bar.visible = true
		
		# Shows GUI after hiding it so you can see it...
		HUD.show()
		$Body/Head/Tilt/Vignette.show()

# ==================== [Debug] ====================
func debug_checker():
	auto_bunny_hopping = GlobalDebug.get_auto_bunny_hopping()
	enable_bunny_hopping = GlobalDebug.get_enable_bunny_hopping()
	disable_run_ticking = GlobalDebug.get_disable_run_ticking()
	noclip = GlobalDebug.get_noclip()

# ==================== [Options Updater] ====================
# FOV, Sens, FPS Display, Speed Display, View Bobbing and Speed Changes FOV Options
#region ---- Options connect ----------------
func connect_global_options():
	GlobalOptions.fov_updated.connect(_on_fov_updated)
	GlobalOptions.mouse_sens_updated.connect(_on_mouse_sens_updated)
	GlobalOptions.fps_displayed.connect(_on_fps_displayed)
	GlobalOptions.speed_displayed.connect(_on_speed_displayed)
	GlobalOptions.view_bobbing_toggled.connect(_on_view_bobbing_toggled)
	GlobalOptions.fov_change_toggled.connect(_on_fov_change_toggled)
	GlobalOptions.sideways_tilt_toggled.connect(_on_sideways_tilt_toggled)
	GlobalOptions.chromatic_abberation_toggled.connect(_on_chromatic_abberation_toggled)

func _on_fov_updated(value):
	fov_base = value
func _on_mouse_sens_updated(value):
	mouse_sens = value
func _on_fps_displayed(value):
	fps_label.visible = value
func _on_speed_displayed(value):
	speed_label.visible = value
func _on_view_bobbing_toggled(toggle):
	option_view_bobbing = toggle
func _on_fov_change_toggled(toggle):
	option_fov_change = toggle
func _on_sideways_tilt_toggled(toggle):
	option_sideways_tilt = toggle
func _on_chromatic_abberation_toggled(toggle):
	option_chromatic_abberation = toggle
#endregion

#region ---- Each visual option code ----------------
func fov_change_option() -> void:
	if option_fov_change == true:
		var velocity_clamped = clamp(velocity.length(), 0.5, top_speed_air * 2)
		var target_fov = fov_base + fov_change * velocity_clamped
		if run == true and crouching_collision.disabled == true:
			target_fov = fov_base + (fov_change * velocity_clamped) * 3
			# I don't rememver why I used to only do it on the Z axis before? What was my past self thinking?
			#if not (( velocity * Vector3(0, 0, 1) ).length()) == 0:
				#target_fov = fov_base + (fov_change * velocity_clamped) * 3
			#else:
				#target_fov = fov_base + fov_change * velocity_clamped
		else:
			target_fov = fov_base + fov_change * velocity_clamped
		camera.fov = lerp(camera.fov, target_fov, edelta * 8.0)
	else:
		camera.fov = fov_base

func view_bobbing_option() -> void:
	if option_view_bobbing == false:
		tilt.transform.origin = _head_view_bobbing(0)
		return
	time_view_bobbing += edelta * velocity.length() * float(is_on_floor())
	tilt.transform.origin = _head_view_bobbing(time_view_bobbing)
func _head_view_bobbing(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bobbing_frequency) * bobbing_amplifier
	pos.x = cos(time * bobbing_frequency / 2) * bobbing_amplifier
	return pos

func sideways_tilt_option() -> void:
	if option_sideways_tilt == false:
		tilt.rotation.z = 0
		return
	
	if noclip == true:
		tilt.rotation.z = 0
		return
	
	if perspective > 1:
		tilt.rotation.z = 0
		return
	
	var tilt_degrees: float = -0.2
	var tilt_interpolation_time: float = 3
#	var direction_clamp = clamp(head.rotation.z, -tilt_degrees, tilt_degrees)
	if game_menu.paused == false:
		if (Input.get_vector("left", "right", "forward", "backward").x) < 0:
			if (Input.get_vector("left", "right", "forward", "backward").y) == 0:
				tilt.rotation.z = lerp(tilt.rotation.z, -tilt_degrees, edelta * tilt_interpolation_time)
			else:
				if (Input.get_vector("left", "right", "forward", "backward").y) > 0:
					tilt.rotation.z = lerp(tilt.rotation.z, -tilt_degrees * 0.5, edelta * tilt_interpolation_time)
				elif (Input.get_vector("left", "right", "forward", "backward").y) < 0:
					tilt.rotation.z = lerp(tilt.rotation.z, -tilt_degrees * 0.5, edelta * tilt_interpolation_time)
		elif (Input.get_vector("left", "right", "forward", "backward").x) > 0:
			if (Input.get_vector("left", "right", "forward", "backward").y) == 0:
				tilt.rotation.z = lerp(tilt.rotation.z, tilt_degrees, edelta * tilt_interpolation_time)
			else:
				if (Input.get_vector("left", "right", "forward", "backward").y) > 0:
					tilt.rotation.z = lerp(tilt.rotation.z, tilt_degrees * 0.5, edelta * tilt_interpolation_time)
				elif (Input.get_vector("left", "right", "forward", "backward").y) < 0:
					tilt.rotation.z = lerp(tilt.rotation.z, tilt_degrees * 0.5, edelta * tilt_interpolation_time)
		else:
			tilt.rotation.z = lerp(tilt.rotation.z, 0.0, edelta * tilt_interpolation_time)
	else:
		tilt.rotation.z = lerp(tilt.rotation.z, 0.0, edelta * tilt_interpolation_time)

func chromatic_abberation_option():
	var shader_code = preload("res://shader/ChromaticAbberation.gdshader")
	var texture: CompressedTexture2D = preload("res://shader/ChromaticAbberationMask.png")
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader_code
	shader_material.set_shader_parameter("strength", 1)
	shader_material.set_shader_parameter("offset_image", texture)
	
	if option_chromatic_abberation == true:
		shader_material.set_shader_parameter("onoff", 1)
		chromatic_abberation.material = shader_material
		chromatic_abberation.visible = true
	else:
		shader_material.set_shader_parameter("onoff", 0)
		chromatic_abberation.material = shader_material
		chromatic_abberation.visible = false
#endregion

# ==================== [Camera] ====================
func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	if Input.is_action_just_pressed("pause"):
		if health.dead == true:
			print("a")
			if game_menu.paused == true:
				deathmenu.background.hide()
				deathmenu.death_menu.hide()
			else:
				deathmenu.background.show()
				deathmenu.death_menu.show()
	
	handle_camera_mouse_movement(event)
func handle_camera_mouse_movement(event):
	# Can't look around when paused.
	if game_menu.paused == true or health.dead == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
	#if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			#head.rotate_y(-event.relative.x * mouse_sens)
			#camera.rotate_x(-event.relative.y * mouse_sens)
			#camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			body.rotate_y(-event.relative.x * mouse_sens)
			head.rotate_x(-event.relative.y * mouse_sens)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			mesh.rotation.y = body.rotation.y + deg_to_rad(180)
			view_model_camera.swing(Vector2(event.relative.x,event.relative.y))
	
	camera.set_as_top_level(true)
	camera_target_position = camera.global_transform.origin
func manage_camera_smoothing(delta):
	camera_current_interpolated_transform = head.get_global_transform()
	camera_target_position = lerp(camera_target_position, camera_current_interpolated_transform.origin, delta * top_speed * stairs_feeling_coefficient * camera_coefficient)
	var camera_target_position_y = lerp(camera_target_position, camera_current_interpolated_transform.origin + (tilt.position*bobbing_frequency_end), delta * top_speed * stairs_feeling_coefficient * camera_coefficient)
	camera.position.x = camera_current_interpolated_transform.origin.x + tilt.position.x
	camera.position.z = camera_current_interpolated_transform.origin.z + tilt.position.x
	
	if is_on_floor():
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
		
	#camera.position.x += tilt.position.x
	#camera.position.y += tilt.position.y
	camera.rotation.z = tilt.rotation.z
	camera.rotation.x = head.rotation.x
	camera.rotation.y = body.rotation.y + body_euler_y

# ==================== [Movement] ====================
func _process(delta):
	edelta = delta
	_handle_3rd_person_head_IK()
	_handle_3rd_person_hand_attack_IK()
	player_attacking_ik(attacking)
	if not is_multiplayer_authority(): return
	
	# Options
	_fps_label()
	fov_change_option()
	view_bobbing_option()
	sideways_tilt_option()
	chromatic_abberation_option()
	
	debug_checker()
	
	perspective_switch()
	
func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	if health.dead == true:
		HUD.visible = false
		return
	
	if just_start_noclip == false: # Then coming out of noclip
		HUD.visible = true
		standing_collision.disabled = false
		crouching_collision.disabled = true
		just_start_noclip = true
	if noclip == true:
		if just_start_noclip == true: # Then going to noclip
			velocity = Vector3.ZERO
			HUD.visible = false
			standing_collision.disabled = true
			crouching_collision.disabled = true
			perspective = 1
			just_start_noclip = false
			
		manage_camera_smoothing(delta)
		_movement_interpolation(delta)
		
		on_noclip(delta)
		move_and_slide()
		return
	
	_speed_label()
	
	# View Model is the same position as the normal camera
	view_model_camera.global_transform = camera.global_transform
	
	# Movement
	handle_moving(delta)
	handle_gravity(delta)
	handle_stairs(delta)
	cap_air_speed()
	lock_sliding_bug()
	health.player_fall_damage()
	
	# Mechanics
	crouching(delta)
	sprinting(delta)
	stamina()
	_run_ticking()
	player_attacking()
	
	manage_camera_smoothing(delta)
	_movement_interpolation(delta)
	
	move_and_slide()

#region ---- Mechanics ----------------
func crouching(delta):
	if game_menu.paused == false: # Can't crouch when paused
		if Input.is_action_pressed("crouch"):
			top_speed = top_speed_crouch
			head_end_position.y = lerp(head_end_position.y,1.9 + crouching_depth,delta*lerp_speed)
			standing_collision.disabled = true
			crouching_collision.disabled = false
			air_speed_cap = top_speed + speed_changer
			#air_speed_cap = top_speed_crouch + 3
		elif !ray_cast_3d.is_colliding():
			top_speed = top_speed_walking
			head_end_position.y = lerp(head_end_position.y,1.9,delta*lerp_speed)
			standing_collision.disabled = false
			crouching_collision.disabled = true
			air_speed_cap = top_speed + speed_changer
			#air_speed_cap = top_speed_walking + 3
func sprinting(delta):
	if game_menu.paused == false: # Can't sprint when paused
		if crouching_collision.disabled == true:
			if not stamina_points <= 0 and run == true:
				if Input.is_action_pressed("sprint"):
					top_speed = top_speed_sprint
					air_speed_cap = top_speed + speed_changer
					#air_speed_cap = top_speed_sprint + 3
					mesh_3rd_animation.set("parameters/walking_time_scale/scale", lerp(mesh_3rd_animation.get("parameters/walking_time_scale/scale"), 4.0, edelta * 30))
			else:
				mesh_3rd_animation.set("parameters/walking_time_scale/scale", lerp(mesh_3rd_animation.get("parameters/walking_time_scale/scale"), 2.0, edelta * 30))
func stamina():
	if stamina_points <= 0:
		stamina_points = 0
	if stamina_points >= 100:
		stamina_points = 100
	
	if (( velocity * Vector3(1, 0, 1) ).length()) == 0 or crouching_collision.disabled == false:
		run_ticking = false
	else:
		if Input.is_action_pressed("sprint"):
			if stamina_points >= 1:
				run = true
				run_ticking = true
				#print("a")
	
	if game_menu.paused == false:
		if Input.is_action_pressed("sprint"):
			if stamina_points >= 1 and run == false:
				run = true
				run_ticking = true
				#print("b")
		else:
			if run == true:
				run = false
				run_ticking = false
	else:
		if run == true:
			run = false
			run_ticking = false
func _run_ticking():
	if disable_run_ticking == true:
		stamina_points = 100
		_stamina_label()
		return
	
	if run_ticking == true:
		if (( velocity * Vector3(1, 0, 1) ).length()) > 0:
			if crouching_collision.disabled == true:
				time_between_sub -= 1
				if time_between_sub <= 0:
					time_between_sub = sub_time
					stamina_points = stamina_points - stamina_loss
					stamina_recharge = false
					_stamina_label()
					#print("stamina loss")
					if stamina_points <= 0:
						run = false
						run_ticking = false
						top_speed = top_speed_walking
						air_speed_cap = top_speed + speed_changer
						#air_speed_cap = top_speed_walking + 3
	else:
		if stamina_points < 100:
			if crouching_collision.disabled == false: # This was by accident but I actually like no delay then crouched
				stamina_recharge = true
				#print("recharge crouched")
			if stamina_recharge == false:
				await get_tree().create_timer(0.5).timeout # Time to start stamina recharge
				#print("recharge")
				stamina_recharge = true
		if stamina_recharge == true:
			time_between_sub2 -= 1
			if time_between_sub2 <= 0:
				time_between_sub2 = sub_time
				stamina_points = stamina_points + stamina_regain
				_stamina_label()
				#print("stamina recharge")
				if stamina_points <= 0:
					run = false
					run_ticking = false
					top_speed = top_speed_walking
					air_speed_cap = top_speed + speed_changer
					#air_speed_cap = top_speed_walking + 3
func player_attacking_func():
	if game_menu.singleplayer == false:
		if punch_ray.is_colliding():
			var collider = punch_ray.get_collider()
			print(punch_ray.get_collider())
			if not (collider is StaticBody3D):
				var hit_player = punch_ray.get_collider()
				hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())
				print(hit_player.get_multiplayer_authority())
func player_attacking():
	if standing_collision.disabled == true:
		if game_menu.paused == true:
			attacking = false
			return
		# Attacking Crouched
		if Input.is_action_just_pressed("attack") && is_on_floor() && !landing_animation_on_fall && attacking == false:
			mesh_3rd_animation.set("parameters/attack_event_crouch/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			view_model_rig_anim.play("Attack")
			attacking = true
			attack_ik_timer.start()
			player_attacking_func()
			$Punch.play()
		
		mesh_3rd_animation.set("parameters/attack_event/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	else:
		if game_menu.paused == true:
			attacking = false
			return
		# Attacking Normal
		if Input.is_action_just_pressed("attack") && is_on_floor() && !landing_animation_on_fall && attacking == false:
			mesh_3rd_animation.set("parameters/attack_event/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			view_model_rig_anim.play("Attack")
			attacking = true
			attack_ik_timer.start()
			player_attacking_func()
			$Punch.play()
		
		mesh_3rd_animation.set("parameters/attack_event_crouch/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
func player_attacking_ik(play: bool):
	if play == false:
		attack_ik_lerp = 0.0
		#looking_ik_lerp = 1.0
	else:
		attack_ik_lerp = 1.0
		#looking_ik_lerp = 0.0
	
	rotate_x_attack_animation_ik.interpolation = lerp(rotate_x_attack_animation_ik.interpolation, attack_ik_lerp, edelta * 30)
	if rotate_x_attack_animation_ik.interpolation == 0.0:
		rotate_x_attack_animation_ik.stop()
	else:
		rotate_x_attack_animation_ik.start()
	#rotate_x_looking_animation_ik.interpolation = lerp(rotate_x_looking_animation_ik.interpolation, looking_ik_lerp, edelta * 30)
	#if rotate_x_looking_animation_ik.interpolation == 0.0:
		#rotate_x_looking_animation_ik.stop()
	#else:
		#rotate_x_looking_animation_ik.start()
func _on_attack_ik_timer_timeout():
	attacking = false
func perspective_switch():
	if noclip == false:
		if health.dead == false:
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
		if standing_collision.disabled == true:
			third_person_body.position.y = lerp(third_person_body.position.y, 1.9 + crouching_depth, edelta * lerp_speed)
		else:
			third_person_body.position.y = lerp(third_person_body.position.y, 1.9, edelta * lerp_speed)
	
	if perspective == 1:
		view_model_camera.visible = true
		camera.current = true
		camera_third.current = false
		#mesh.show()
		mesh_skin.set_cast_shadows_setting(3)
		reticle.visible = true
	elif perspective == 2:
		view_model_camera.visible = false
		camera.current = false
		camera_third.current = true
		#mesh.show()
		mesh_skin.set_cast_shadows_setting(1)
		reticle.visible = false
	elif perspective == 3:
		view_model_camera.visible = false
		camera.current = false
		camera_third.current = true
		#mesh.show()
		mesh_skin.set_cast_shadows_setting(1)
		reticle.visible = false
#endregion

#region ---- Moving and 3rd person animations ----------------
func handle_moving(delta):
	# Get the input direction
	direction_wish_to_go = Vector3.ZERO
	var horizontal_rotation: float = body.global_transform.basis.get_euler().y
	var forward_input: float = Input.get_action_strength("backward") - Input.get_action_strength("forward")
	var horizontal_input: float = Input.get_action_strength("right") - Input.get_action_strength("left")
	var input_direction: Vector2 = Input.get_vector("left", "right", "forward", "backward")
	
	# Can't move when paused
	if game_menu.paused == false:
		direction_wish_to_go = Vector3(horizontal_input, 0, forward_input).rotated(Vector3.UP, horizontal_rotation).normalized()
		#direction_wish_to_go = (head.transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	else:
		direction_wish_to_go = Vector3.ZERO
	
	projected_speed = (velocity * Vector3(1, 0, 1)).dot(direction_wish_to_go)
	
	_handle_3rd_person_animations(input_direction, delta)
func _handle_3rd_person_animations(input_direction, delta):
	# Old Code for the old animation tree state machine
	#mesh_3rd_animation.set("parameters/conditions/idle", standing_collision.disabled == false && input_direction == Vector2.ZERO && is_on_floor())
	#mesh_3rd_animation.set("parameters/conditions/moving_forward", standing_collision.disabled == false && input_direction.y == -1 && is_on_floor())
	#mesh_3rd_animation.set("parameters/conditions/moving_backward", standing_collision.disabled == false && input_direction.y == 1 && is_on_floor())
	#mesh_3rd_animation.set("parameters/conditions/moving_left", standing_collision.disabled == false && input_direction.x == -1 && is_on_floor())
	#mesh_3rd_animation.set("parameters/conditions/moving_right", standing_collision.disabled == false && input_direction.x == 1 && is_on_floor())
	#mesh_3rd_animation.set("parameters/conditions/crouch", standing_collision.disabled == true && is_on_floor())
	#mesh_3rd_animation.set("parameters/conditions/jump", !is_on_floor())
	
	if !is_on_floor():
		landing_animation_on_fall = true
	
	# If game is paused, don't animate
	if game_menu.paused == true:
		if standing_collision.disabled == true:
			# Crouch
			if is_on_floor():
				mesh_3rd_animation.set("parameters/crouched/blend_position", lerp(mesh_3rd_animation.get("parameters/crouched/blend_position"), Vector2(0, 0), delta * acceleration_ground))
		else:
			# Normal
			if is_on_floor():
				mesh_3rd_animation.set("parameters/walking/blend_position", lerp(mesh_3rd_animation.get("parameters/walking/blend_position"), Vector2(0, 0), delta * acceleration_ground))
			return # don't run the code below
	
	# Handles the walking and crouching animations as well for the crouching animation itself and on falling
	if standing_collision.disabled == true:
		# Crouch event on crouched walking animation
		mesh_3rd_animation.set("parameters/crouch_event/blend_amount", lerp(mesh_3rd_animation.get("parameters/crouch_event/blend_amount"), 1.0, delta * acceleration_ground))
		if is_on_floor() && ((( velocity * Vector3(0, 0, 1) ).length()) > 0.5 || (( velocity * Vector3(1, 0, 0) ).length()) > 0.5):
			mesh_3rd_animation.set("parameters/crouched/blend_position", lerp(mesh_3rd_animation.get("parameters/crouched/blend_position"), input_direction, delta * acceleration_ground))
		else:
			mesh_3rd_animation.set("parameters/crouched/blend_position", lerp(mesh_3rd_animation.get("parameters/crouched/blend_position"), Vector2(0, 0), delta * 20))
	else:
		# Crouch event on normal walking animation
		mesh_3rd_animation.set("parameters/crouch_event/blend_amount", lerp(mesh_3rd_animation.get("parameters/crouch_event/blend_amount"), 0.0, delta * acceleration_ground))
		if is_on_floor() && ((( velocity * Vector3(0, 0, 1) ).length()) > 0.5 || (( velocity * Vector3(1, 0, 0) ).length()) > 0.5):
			mesh_3rd_animation.set("parameters/walking/blend_position", lerp(mesh_3rd_animation.get("parameters/walking/blend_position"), input_direction, delta * acceleration_ground))
		else:
			mesh_3rd_animation.set("parameters/walking/blend_position", lerp(mesh_3rd_animation.get("parameters/walking/blend_position"), Vector2(0, 0), delta * 20))
	
	# Jumping animation is at "ground_move(delta)"
	# Attacking is at "player_attacking()"
	# Landing animation is at "handle_gravity(delta)"
func _handle_3rd_person_head_IK():
	rotate_x_looking_animation_target.rotation.x = -camera.rotation.x
func _handle_3rd_person_hand_attack_IK():
	rotate_x_attack_animation_target.rotation.x = -camera.rotation.x
#endregion

#region ---- Jumping, air movement, friction, gravity, acceleration, and velocity ----------------
func ground_move(delta):
	floor_snap_length = 0.4
	apply_acceleration(acceleration_ground, top_speed, delta)
	
	# Jumping
	if game_menu.paused == false: # Can't jump when paused
		if !ray_cast_3d.is_colliding(): # Can't jump when under objects
			if Input.is_action_just_pressed("jump") or Input.is_action_pressed("jump") and jump_twice == false:
				snap = Vector3.ZERO
				gravity_vector = Vector3.UP * jump_force
				velocity.y = jump_force
				if auto_bunny_hopping == true: 
					jump_twice = false
					#await get_tree().create_timer(0.1).timeout
					#landing_animation_on_fall = true
				else:
					jump_twice = true
					# Do the third person jumping animation
					mesh_3rd_animation.set("parameters/jump_event/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
					# Jumping removes stamina but doesn't need stamina to be able to be done
					stamina_recharge = false
					stamina_points -= 2
					_stamina_label()
					#await get_tree().create_timer(0.1).timeout
					#landing_animation_on_fall = true
					await get_tree().create_timer(1).timeout # Time to start stamina recharge
					stamina_recharge = true
	
	if grounded:
		apply_friction(delta)
	
	if is_on_wall:
		clip_velocity(get_wall_normal(), 1, delta)
func air_move(delta):
	apply_acceleration(acceleration_air, top_speed_air, delta)
	clip_velocity(get_wall_normal(), 14, delta)
	clip_velocity(get_floor_normal(), 14, delta)
	velocity.y -= gravity * delta
func clip_velocity(normal: Vector3, overbounce: float, delta) -> void:
	var correction_amount: float = 0
	var correction_dir: Vector3 = Vector3.ZERO
	var move_vector: Vector3 = get_velocity().normalized()
	
	correction_amount = move_vector.dot(normal) * overbounce
	correction_dir = normal * correction_amount
	velocity -= correction_dir
	velocity.y -= correction_dir.y * (gravity/20) # With a gravity so high, I use this to account for it and allow surfing
func apply_friction(delta):
	var speed_scalar: float = 0
	var friction_curve: float = 0
	var speed_loss: float = 0
	var current_speed: float = 0
	
	current_speed = velocity.length() # Using projected velocity will lead to no friction being applied in certain scenarios, like if "direction_wish_to_go" is perpendicular, if "direction_wish_to_go" is obtuse from movement it would create negative friction and fling players
	if(current_speed < 0.1):
		velocity.x = 0
		velocity.y = 0
		return
	
	friction_curve = clampf(current_speed, linearize_friction_speed_below_this_speed, INF)
	speed_loss = friction_curve * friction * delta
	speed_scalar = clampf(current_speed - speed_loss, 0, INF)
	speed_scalar /= clampf(current_speed, 1, INF)
	
	velocity *= speed_scalar
func apply_acceleration(acceleration: float, top_speed: float, delta):
	var speed_remaining: float = 0
	var acceleration_final: float = 0
	
	speed_remaining = (top_speed * direction_wish_to_go.length()) - projected_speed
	if speed_remaining <= 0:
		return
	
	acceleration_final = acceleration * delta * top_speed
	clampf(acceleration_final, 0, speed_remaining)
	velocity.x += acceleration_final * direction_wish_to_go.x
	velocity.z += acceleration_final * direction_wish_to_go.z
func handle_gravity(delta):
	if not is_on_floor():
		grounded = false
		air_move(delta)
		snap = Vector3.DOWN
		gravity_vector += Vector3.DOWN * gravity * delta
	if is_on_floor():
		snap = -get_floor_normal()
		gravity_vector = Vector3.ZERO
		if velocity.y > 10:
			grounded = false
			air_move(delta)
		else:
			grounded = true
			ground_move(delta)
	
	# Don't jump twice
	if is_on_floor() and jump_twice == true and not Input.is_action_pressed("jump") and auto_bunny_hopping == false:
		jump_twice = false
	if is_on_floor() and landing_animation_on_fall == true:
		mesh_3rd_animation.set("parameters/land_event/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		landing_animation_on_fall = false

func on_noclip(delta):
	if game_menu.paused == true:
		velocity = Vector3.ZERO
		direction_wish_to_go = Vector3.ZERO
		return
	
	# Get the input direction
	direction_wish_to_go = Vector3.ZERO
	var camera_rotation: Basis = camera.global_transform.basis
	#var forward_input: float = Input.get_action_strength("backward") - Input.get_action_strength("forward")
	#var horizontal_input: float = Input.get_action_strength("right") - Input.get_action_strength("left")
	var local_direction = Vector3(Input.get_action_strength("right") - Input.get_action_strength("left"), 0, Input.get_action_strength("backward") - Input.get_action_strength("forward"))
	var input_direction: Vector2 = Input.get_vector("left", "right", "forward", "backward")
	
	direction_wish_to_go = (camera_rotation*local_direction).normalized()
	
	#direction_wish_to_go = Vector3(horizontal_input, 0, forward_input).rotated(Vector3.UP, camera_rotation.get_euler().y).normalized()
	
	#direction_wish_to_go = Vector3(horizontal_input, 0, forward_input)
	#var direction_wish_to_go_y = direction_wish_to_go.rotated(Vector3.UP, camera_rotation.get_euler().y).normalized()
	#var direction_wish_to_go_x = direction_wish_to_go.rotated(Vector3.RIGHT, camera_rotation.get_euler().x).normalized()
	#direction_wish_to_go = Vector3(direction_wish_to_go_y.x, direction_wish_to_go_x.y, direction_wish_to_go_y.z)
	
	var noclip_speed_now = noclip_speed
	
	if Input.is_action_pressed("sprint"):
		noclip_speed_now = noclip_speed * 2
	elif Input.is_action_pressed("jump") and Input.is_action_pressed("crouch"):
		noclip_speed_now = noclip_speed / 2
	else:
		noclip_speed_now = noclip_speed
	
	if Input.is_action_pressed("jump"):
		velocity.y += noclip_speed_now
	
	if Input.is_action_pressed("crouch"):
		velocity.y -= noclip_speed_now
	
	velocity += noclip_speed_now * direction_wish_to_go
	#velocity.x += noclip_speed_now * direction_wish_to_go.x
	#velocity.z += noclip_speed_now * direction_wish_to_go.z
	#velocity.y += noclip_speed_now * direction_wish_to_go.y
	
	#velocity.y += noclip_speed_now * clamp(camera_rotation.get_euler().x, -1.0, 1.0)
	
	_handle_3rd_person_animations(input_direction, delta)
#endregion

#region ---- Bug fixes ----------------
# Cap air speed to not pass the limit.
# This can be bad if I had cars or other object that push the player.
# It's a solid fix and not fluid, so crouching and uncrouching mid air is affected.
func cap_air_speed():
	if enable_bunny_hopping == true:
		return
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	if horizontal_velocity.length() >= air_speed_cap:
		horizontal_velocity = horizontal_velocity.normalized() * air_speed_cap
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z

# This makes the player speed 0 if it is less than 0.2.
# It's a bad way to fix a bug, it should be fixed from root, but this is the fastest fix.
# The root problem probably comes from apply_friction.
func lock_sliding_bug():
	if not crouching_collision.disabled == false: # This is so start walking while crouched isn't scuffed.
		if (( velocity * Vector3(0, 0, 1) ).length()) < 0.2: # It applies everytime while standing.
			velocity.z = 0
	else:
		if (Input.get_vector("left", "right", "forward", "backward")) == Vector2.ZERO: # But for crouch it checks for player inputs.
			if (( velocity * Vector3(0, 0, 1) ).length()) < 0.2: # And then applies it, this is so you can start walk crounching after standing.
				velocity.z = 0

# Movement Jittery on Higher Framerate Fix - Interpolation
# Only works on X and Z axis because I can't seem to fix Y axis.
# It's also a solid way to fix it, a better way could be to rewrite the physics
# movement or just make the physic ticks larger than 60, but that's a bad fix.
func _movement_interpolation(delta):
	var fps = Engine.get_frames_per_second()
	var meshob = head
	var lerp_interval = head_end_position / fps
	var lerp_position = global_transform.origin + lerp_interval
	
	#if fps > 60:
	meshob.set_as_top_level(true)
	var lerp_xz = meshob.global_transform.origin.lerp(lerp_position, 50 * delta)
	meshob.position.x = lerp_xz.x
	meshob.position.z = lerp_xz.z
	var lerp_y = global_transform.origin + head_end_position # Head position bugs so I have to use default without "lerp"
	meshob.position.y = lerp_y.y
	#else:
		#meshob.set_as_top_level(true)
		#meshob.position = head_end_position

# This fixes the getting stuck on ground and makes kinda makes stairs possible
func handle_stairs(delta) -> void:
	is_step = false
	
	if gravity_vector.y >= 0:
		for i in range(step_check_count):
			var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
			
			var step_height: Vector3 = step_height_default - i * step_check_height
			var transform3d: Transform3D = global_transform
			var motion: Vector3 = step_height
			
			var is_player_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
			
			if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).y < 0:
				continue
				
			if not is_player_collided:
				transform3d.origin += step_height
				motion = velocity * delta
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
				if not is_player_collided:
					transform3d.origin += motion
					motion = -step_height
					is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
					if is_player_collided:
						if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(step_max_slope_degree):
							head_offset = -test_motion_result.get_remainder()
							is_step = true
							global_transform.origin += -test_motion_result.get_remainder()
							break
				else:
					var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal(0)
	
					transform3d.origin += test_motion_result.get_collision_normal(0) * wall_margin
					motion = (velocity * delta).slide(wall_collision_normal)
					is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
					if not is_player_collided:
						transform3d.origin += motion
						motion = -step_height
						is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
						if is_player_collided:
							if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(step_max_slope_degree):
								head_offset = -test_motion_result.get_remainder()
								is_step = true
								global_transform.origin += -test_motion_result.get_remainder()
								break
			else:
				var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal(0)
				transform3d.origin += test_motion_result.get_collision_normal(0) * wall_margin
				motion = step_height
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
				if not is_player_collided:
					transform3d.origin += step_height
					motion = (velocity * delta).slide(wall_collision_normal)
					is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
					if not is_player_collided:
						transform3d.origin += motion
						motion = -step_height
						is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
						if is_player_collided:
							if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(step_max_slope_degree):
								head_offset = -test_motion_result.get_remainder()
								is_step = true
								global_transform.origin += -test_motion_result.get_remainder()
								break
	
	var is_falling: bool = false
	
	if not is_step and is_on_floor():
		var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		var step_height: Vector3 = step_height_default
		var transform3d: Transform3D = global_transform
		var motion: Vector3 = velocity * delta
		var is_player_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
		
		if not is_player_collided:
			transform3d.origin += motion
			motion = -step_height
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
			if is_player_collided:
				if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(step_max_slope_degree):
					head_offset = test_motion_result.get_travel()
					is_step = true
					global_transform.origin += test_motion_result.get_travel()
			else:
				is_falling = true
		else:
			if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).y == 0:
				var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal(0)
				transform3d.origin += test_motion_result.get_collision_normal(0) * wall_margin
				motion = (velocity * delta).slide(wall_collision_normal)
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
				if not is_player_collided:
					transform3d.origin += motion
					motion = -step_height
					is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), params(transform3d, motion), test_motion_result)
					if is_player_collided:
						if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(step_max_slope_degree):
							head_offset = test_motion_result.get_travel()
							is_step = true
							global_transform.origin += test_motion_result.get_travel()
					else:
						is_falling = true
		
	if is_step:
		top_speed = top_speed_stairs
	else:
		head_offset = head_offset.lerp(Vector3.ZERO, delta * top_speed * stairs_feeling_coefficient)
		
		if abs(head_offset.y) <= 0.01:
			if crouching_collision.disabled == true:
				top_speed = top_speed_walking
			else:
				top_speed = top_speed_crouch
	
	#velocity += gravity_vector
	
	if is_falling:
		snap = Vector3.ZERO
func params(transform3d, motion):
	var params : PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
	params.from = transform3d
	params.motion = motion
	params.recovery_as_collision = true
	return params
#endregion

# ==================== [Labels] ====================
func _fps_label(): # Can be found in _progress()
	fps_label.text = "FPS: %s" % [Engine.get_frames_per_second()]
func _speed_label(): # Can be found in _physics_process()
	speed_label.text = str( int( ( velocity * Vector3(1, 0, 1) ).length() ) )
func _stamina_label(): # Can be found in _run_ticking()
#	stamina_label.text = "Stamina: " + str(stamina_points)
	stamina_bar.value = stamina_points
	get_tree().create_tween().tween_property(stamina_bar, "value", stamina_bar.value, 0.1).set_trans(Tween.TRANS_SINE)
	
	# Desappear and happear
	if stamina_bar.value > 95:
		stamina_bar.set_tint_progress(Color(0.76, 1, 1, 0))
	else:
		stamina_bar.set_tint_progress(Color(0.76, 1, 1, 1))
	get_tree().create_tween().tween_property(stamina_bar, "tint_progress", stamina_bar.tint_progress, 0.2).set_trans(Tween.TRANS_EXPO)
	
	#if noclip == true:
		#if stamina_bar.value == 100:
			#stamina_bar.set_tint_progress(Color(0.76, 1, 1, 0))
			#get_tree().create_tween().tween_property(stamina_bar, "tint_progress", stamina_bar.tint_progress, 0.05).set_trans(Tween.TRANS_LINEAR)

# ==================== [Multiplayer] ====================
@rpc("unreliable","any_peer","call_local") func update_position(id, u_position, u_motion_mode, u_mesh, u_camera):
	if is_multiplayer_authority(): return
	if name != id: return
	position = lerp(position, u_position, edelta * 50)
	motion_mode = lerp(motion_mode, u_motion_mode, edelta * 10)
	mesh.rotation = u_mesh # This can't be lerped (lerp bug then lerping rotations)
	camera.rotation.x = lerp(camera.rotation.x, u_camera, edelta * 30)

@rpc("unreliable","any_peer","call_local") func update_animation(id, u_animation_player, u_animation_tree, u_head_ik, parameter_crouch, parameter_crouched, parameter_jump, parameter_land, parameter_walking, u_landing, crouched_time_scale, walking_time_scale):
	if is_multiplayer_authority(): return
	if name != id: return
	mesh_3rd_animation_player.current_animation = u_animation_player
	mesh_3rd_animation.anim_player = u_animation_tree
	rotate_x_looking_animation_ik.interpolation = u_head_ik
	mesh_3rd_animation["parameters/crouch_event/blend_amount"] = parameter_crouch
	mesh_3rd_animation["parameters/crouched/blend_position"] = parameter_crouched
	mesh_3rd_animation["parameters/jump_event/request"] = parameter_jump
	mesh_3rd_animation["parameters/land_event/request"] = parameter_land
	mesh_3rd_animation["parameters/walking/blend_position"] = parameter_walking
	landing_animation_on_fall = u_landing
	mesh_3rd_animation["parameters/crouched_time_scale/scale"] = crouched_time_scale
	mesh_3rd_animation["parameters/walking_time_scale/scale"] = walking_time_scale

@rpc("unreliable","any_peer","call_local") func update_attack(id, parameter_attack, parameter_attack_crouch, u_attacking):
	if is_multiplayer_authority(): return
	if name != id: return
	#rotate_x_attack_animation_ik.interpolation = u_hand_attack_ik
	mesh_3rd_animation["parameters/attack_event/request"] = parameter_attack # Attack animation
	mesh_3rd_animation["parameters/attack_event_crouch/request"] = parameter_attack_crouch # Attack animation
	attacking = u_attacking # Yeah, uh, the IK thingy

#@rpc("any_peer","call_local") func on_attack_animation(id):
	#if is_multiplayer_authority(): return
	#if name != id: return
	#pass
	## rpc("on_attack_animation", name)

func _on_player_tickrate_timeout():
	if !is_multiplayer_authority(): return
	rpc("update_position", name, position, motion_mode, mesh.rotation, camera.rotation.x)
	rpc("update_animation", name, mesh_3rd_animation_player.current_animation, mesh_3rd_animation.anim_player, rotate_x_looking_animation_ik.interpolation, mesh_3rd_animation["parameters/crouch_event/blend_amount"], mesh_3rd_animation["parameters/crouched/blend_position"], mesh_3rd_animation["parameters/jump_event/request"], mesh_3rd_animation["parameters/land_event/request"], mesh_3rd_animation["parameters/walking/blend_position"], landing_animation_on_fall, mesh_3rd_animation["parameters/crouched_time_scale/scale"], mesh_3rd_animation["parameters/walking_time_scale/scale"])
	rpc("update_attack", name, mesh_3rd_animation["parameters/attack_event/request"], mesh_3rd_animation["parameters/attack_event_crouch/request"], attacking)

@rpc("any_peer") func receive_damage():
	health.do_damage(10)
