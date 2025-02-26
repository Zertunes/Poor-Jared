extends CharacterBody3D
#Thanks to EthanTheEnigma for the movement code inpired by the Source Engine. https://www.youtube.com/watch?v=45ERGbDV050&ab_channel=EthanTheEnigma (Code reorginazed, rewriten, edited and changed)

@onready var GAMEMENU = get_parent().get_parent().get_node("GameMenu")
@export var HUD: Node
@export var STAMINA: Node
@export var SOUNDS: Node
@export var ATTACKING: Node
@export var MOVEMENT: Node
@export var HEALTH: Node
@export var FstP: Node
@export var TrdP: Node
@export var MULTIPLAYER: Node

@onready var chromatic_abberation: ColorRect = $Body/Head/Tilt/ChromaticAbberation
@onready var shader_material: ShaderMaterial

@onready var edelta = 0

# View Bobbing
var bobbing_frequency = 2.0
var bobbing_amplifier = 0.08
var time_view_bobbing =  0.0

# FOV
var fov_base = 70
var fov_change = 1.5

# Options for view bobbing, sideways tilt, FOV change and mouse sensitivity
var option_view_bobbing = true
var option_fov_change = true
var option_sideways_tilt = true
var option_chromatic_abberation = true
var mouse_sens = 0.002

func _enter_tree():
	set_multiplayer_authority(name.to_int())
func _ready():
	loading_hiding(true)
	
	if not is_multiplayer_authority(): return
	loading_hiding(false)
	
	connect_global_options()
	HUD._stamina_label()
	HEALTH.connect_health_component()
	HUD.connect_world_env_component()
	
	# Time
	HUD._on_hour_changed(6, true)
	HUD._on_day_changed(0)

# ==================== [Loading] ====================
# This controls hiding and displaying stuff on start,
# it is awesome for stuff like local client and
# multiplayer client differences.
func loading_hiding(hide: bool): 
	if hide == true: # This is on start, for hiding multiplayer. (Remote)
		# Hides 1st person view model for other players
		FstP.view_model_camera.set_cull_mask_value(2, false)
		FstP.view_model_rig.visible = false
		# Starts the SkeletonIK3D rotation for the 3rd person head
		TrdP.rotate_x_looking_animation_ik.start()
		TrdP.rotate_x_attack_animation_ik.stop()
		# Hides the Stamina bar
		HUD.stamina_bar.visible = false
		# Hides player GUI so it doesn't multiply on multiplayer
		HUD.hide()
		HUD.vignette.hide()
		# Hide the death screen
		HUD.deathmenu.background.hide()
		HUD.deathmenu.death_menu.hide()
	if hide == false: # This is after hiding, to show. (Local)
		# Shows 1st person view model for local player
		FstP.view_model_camera.set_cull_mask_value(2, true)
		FstP.view_model_rig.visible = true
		# Makes the size of the first person view model the same as the screen (in 1st person)
		FstP.view_model_viewport.size = DisplayServer.window_get_size()
		# Makes the camera the current one
		FstP.camera.current = true
		# Hides 3rd person character from local player (Doesn't need to be used now because I added perspectives (and there are shadows in first person))
		#mesh.hide()
		# Shows the Stamina bar
		HUD.stamina_bar.visible = true
		
		# Shows GUI after hiding it so you can see it...
		HUD.show()
		HUD.vignette.show()

# ==================== [Options Updater] ====================
# FOV, Sens, FPS Display, Speed Display, View Bobbing and Speed Changes FOV Options
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
	HUD.fps_label.visible = value
func _on_speed_displayed(value):
	HUD.speed_label.visible = value
func _on_view_bobbing_toggled(toggle):
	option_view_bobbing = toggle
func _on_fov_change_toggled(toggle):
	option_fov_change = toggle
func _on_sideways_tilt_toggled(toggle):
	option_sideways_tilt = toggle
func _on_chromatic_abberation_toggled(toggle):
	option_chromatic_abberation = toggle

# ==================== [Options Visuals] ====================
func fov_change_option() -> void:
	if option_fov_change == true:
		var velocity_clamped = clamp(velocity.length(), 0.5, MOVEMENT.top_speed_air * 2)
		var target_fov = fov_base + fov_change * velocity_clamped
		if STAMINA.run == true and MOVEMENT.crouching_collision.disabled == true:
			target_fov = fov_base + (fov_change * velocity_clamped) * 3
			# I don't rememver why I used to only do it on the Z axis before? What was my past self thinking?
			#if not (( velocity * Vector3(0, 0, 1) ).length()) == 0:
				#target_fov = fov_base + (fov_change * velocity_clamped) * 3
			#else:
				#target_fov = fov_base + fov_change * velocity_clamped
		else:
			target_fov = fov_base + fov_change * velocity_clamped
		FstP.camera.fov = lerp(FstP.camera.fov, target_fov, edelta * 8.0)
	else:
		FstP.camera.fov = fov_base

func view_bobbing_option() -> void:
	if option_view_bobbing == false:
		FstP.tilt.transform.origin = _head_view_bobbing(0)
		return
	time_view_bobbing += edelta * velocity.length() * float(is_on_floor())
	FstP.tilt.transform.origin = _head_view_bobbing(time_view_bobbing)
func _head_view_bobbing(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bobbing_frequency) * bobbing_amplifier
	pos.x = cos(time * bobbing_frequency / 2) * bobbing_amplifier
	return pos

func sideways_tilt_option() -> void:
	if option_sideways_tilt == false:
		FstP.tilt.rotation.z = 0
		return
	
	if GlobalDebug.noclip == true:
		FstP.tilt.rotation.z = 0
		return
	
	if TrdP.perspective > 1:
		FstP.tilt.rotation.z = 0
		return
	
	var tilt_degrees: float = -0.2
	var tilt_interpolation_time: float = 3
	var tilt = FstP.tilt
#	var direction_clamp = clamp(head.rotation.z, -tilt_degrees, tilt_degrees)
	if GAMEMENU.paused == false:
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

# ==================== [Movement & Processes] ====================
func _process(delta):
	edelta = delta
	
	TrdP._handle_3rd_person_head_IK()
	TrdP._handle_3rd_person_hand_attack_IK()
	ATTACKING.player_attacking_ik(ATTACKING.attacking)
	if not is_multiplayer_authority(): return
	
	# Options
	HUD._fps_label()
	fov_change_option()
	view_bobbing_option()
	sideways_tilt_option()
	chromatic_abberation_option()
	
	GlobalDebug.debug_checker()
	
	TrdP.perspective_switch()
	
func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	if HEALTH.dead == true:
		HUD.visible = false
		return
	
	if GlobalDebug.just_start_noclip == false: # Then coming out of noclip
		HUD.visible = true
		MOVEMENT.standing_collision.disabled = false
		MOVEMENT.crouching_collision.disabled = true
		set_collision_mask_value(5, true)
		GlobalDebug.just_start_noclip = true
	if GlobalDebug.noclip == true:
		if GlobalDebug.just_start_noclip == true: # Then going to noclip
			velocity = Vector3.ZERO
			HUD.visible = false
			MOVEMENT.standing_collision.disabled = true
			MOVEMENT.crouching_collision.disabled = true
			set_collision_mask_value(5, false)
			GlobalDebug.just_start_noclip = false
			
		FstP.manage_camera_smoothing(delta)
		MOVEMENT._movement_interpolation(delta)
		
		MOVEMENT.on_noclip(delta)
		move_and_slide()
		return
	
	HUD._speed_label()
	
	# View Model is the same position as the normal camera
	FstP.view_model_camera.global_transform = FstP.camera.global_transform
	
	# Movement
	MOVEMENT.handle_moving(delta)
	MOVEMENT.handle_gravity(delta)
	MOVEMENT.handle_stairs(delta)
	MOVEMENT.cap_air_speed()
	MOVEMENT.lock_sliding_bug()
	
	if GAMEMENU.singleplayer:
		SOUNDS.footstepsthingy()
	
	# Mechanics
	MOVEMENT.crouching(delta)
	MOVEMENT.sprinting(delta)
	STAMINA.stamina()
	STAMINA._run_ticking()
	ATTACKING.player_attacking()
	
	FstP.manage_camera_smoothing(delta)
	MOVEMENT._movement_interpolation(delta)
	
	move_and_slide()
