extends Node

@export var PLAYER: CharacterBody3D
@export var STAMINA: Node
@export var FstP: Node
@export var TrdP: Node
@export var SOUNDS: Node
@export var HUD: Control
@onready var GAMEMENU = get_parent().get_parent().get_parent().get_node("GameMenu")

@onready var walking_lerp = Vector2.ZERO
@export var standing_collision: CollisionShape3D
@export var crouching_collision: CollisionShape3D
@export var ray_cast_3d: RayCast3D

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
var head_offset: Vector3 = Vector3.ZERO
var is_step: bool = false
var wall_margin: float = 0.001
var step_height_default: Vector3 = Vector3(0, 0.6, 0)
var step_max_slope_degree: float = 0.0
var step_check_count: int = 2
var step_check_height: Vector3 = step_height_default / step_check_count
# Air
var jump_force: float = 13 #14
var projected_speed: float = 0 # Speed to add and remove then moving on the ground and air (changing this will do no effect, it is calculated on _physics_process)
var acceleration_air: float = 40 #14 # 4 for quake 2/3 40 for quake 1/source
var jump_twice = false
# Debug
var noclip_speed: float = 40.0

func crouching(delta):
	if GAMEMENU.paused == true: # Can't crouch when paused
		return
	if Input.is_action_pressed("crouch"):
		top_speed = top_speed_crouch
		head_end_position.y = lerp(head_end_position.y,1.9 + crouching_depth,delta*lerp_speed)
		standing_collision.disabled = true
		crouching_collision.disabled = false
		air_speed_cap = top_speed + speed_changer
		
	#elif !ray_cast_3d.is_colliding():
	else:
		top_speed = top_speed_walking
		head_end_position.y = lerp(head_end_position.y,1.9,delta*lerp_speed)
		standing_collision.disabled = false
		crouching_collision.disabled = true
		air_speed_cap = top_speed + speed_changer

func sprinting(delta):
	if GAMEMENU.paused == true: # Can't sprint when paused
		return
	if crouching_collision.disabled == true:
		if not STAMINA.stamina_points <= 0 and STAMINA.run == true:
			if Input.is_action_pressed("sprint"):
				top_speed = top_speed_sprint
				air_speed_cap = top_speed + speed_changer
				#air_speed_cap = top_speed_sprint + 3
				TrdP.mesh_3rd_animation.set("parameters/walking_time_scale/scale", lerp(TrdP.mesh_3rd_animation.get("parameters/walking_time_scale/scale"), 4.0, PLAYER.edelta * 30))
		else:
			TrdP.mesh_3rd_animation.set("parameters/walking_time_scale/scale", lerp(TrdP.mesh_3rd_animation.get("parameters/walking_time_scale/scale"), 2.0, PLAYER.edelta * 30))

func handle_moving(delta):
	# Get the input direction
	direction_wish_to_go = Vector3.ZERO
	var horizontal_rotation: float = FstP.body.global_transform.basis.get_euler().y
	var forward_input: float = Input.get_action_strength("backward") - Input.get_action_strength("forward")
	var horizontal_input: float = Input.get_action_strength("right") - Input.get_action_strength("left")
	var input_direction: Vector2 = Input.get_vector("left", "right", "forward", "backward")
	
	# Can't move when paused
	if GAMEMENU.paused == false:
		direction_wish_to_go = Vector3(horizontal_input, 0, forward_input).rotated(Vector3.UP, horizontal_rotation).normalized()
		#direction_wish_to_go = (head.transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	else:
		direction_wish_to_go = Vector3.ZERO
	
	projected_speed = (PLAYER.velocity * Vector3(1, 0, 1)).dot(direction_wish_to_go)
	
	TrdP._handle_3rd_person_animations(input_direction, delta)

# ==================== [Jumping] ====================
func ground_move(delta):
	PLAYER.floor_snap_length = 0.4
	apply_acceleration(acceleration_ground, top_speed, delta)
	
	# Jumping
	if GAMEMENU.paused == false: # Can't jump when paused
		if !ray_cast_3d.is_colliding(): # Can't jump when under objects
			if Input.is_action_just_pressed("jump") or Input.is_action_pressed("jump") and jump_twice == false:
				snap = Vector3.ZERO
				gravity_vector = Vector3.UP * jump_force
				PLAYER.velocity.y = jump_force
				SOUNDS.jump.play()
				if Debug.auto_bunny_hopping == true: 
					jump_twice = false
					#await get_tree().create_timer(0.1).timeout
					#landing_animation_on_fall = true
				else:
					jump_twice = true
					# Do the third person jumping animation
					TrdP.mesh_3rd_animation.set("parameters/jump_event/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
					# Jumping removes stamina but doesn't need stamina to be able to be done
					STAMINA.stamina_recharge = false
					STAMINA.stamina_points -= 2
					HUD._stamina_label()
					#await get_tree().create_timer(0.1).timeout
					#landing_animation_on_fall = true
					await get_tree().create_timer(1).timeout # Time to start stamina recharge
					STAMINA.stamina_recharge = true
	
	if grounded:
		apply_friction(delta)
	
	if PLAYER.is_on_wall:
		clip_velocity(PLAYER.get_wall_normal(), 1, delta)

# ==================== [Air Movement] ====================
func air_move(delta):
	apply_acceleration(acceleration_air, top_speed_air, delta)
	clip_velocity(PLAYER.get_wall_normal(), 14, delta)
	clip_velocity(PLAYER.get_floor_normal(), 14, delta)
	PLAYER.velocity.y -= gravity * delta

# ==================== [Velocity] ====================
func clip_velocity(normal: Vector3, overbounce: float, delta) -> void:
	var correction_amount: float = 0
	var correction_dir: Vector3 = Vector3.ZERO
	var move_vector: Vector3 = PLAYER.get_velocity().normalized()
	
	correction_amount = move_vector.dot(normal) * overbounce
	correction_dir = normal * correction_amount
	PLAYER.velocity -= correction_dir
	PLAYER.velocity.y -= correction_dir.y * (gravity/20) # With a gravity so high, I use this to account for it and allow surfing

# ==================== [Friction] ====================
func apply_friction(delta):
	var speed_scalar: float = 0
	var friction_curve: float = 0
	var speed_loss: float = 0
	var current_speed: float = 0
	
	current_speed = PLAYER.velocity.length() # Using projected velocity will lead to no friction being applied in certain scenarios, like if "direction_wish_to_go" is perpendicular, if "direction_wish_to_go" is obtuse from movement it would create negative friction and fling players
	if(current_speed < 0.1):
		PLAYER.velocity.x = 0
		PLAYER.velocity.y = 0
		return
	
	friction_curve = clampf(current_speed, linearize_friction_speed_below_this_speed, INF)
	speed_loss = friction_curve * friction * delta
	speed_scalar = clampf(current_speed - speed_loss, 0, INF)
	speed_scalar /= clampf(current_speed, 1, INF)
	
	PLAYER.velocity *= speed_scalar

# ==================== [Acceleration] ====================
func apply_acceleration(acceleration: float, top_speed: float, delta):
	var speed_remaining: float = 0
	var acceleration_final: float = 0
	
	speed_remaining = (top_speed * direction_wish_to_go.length()) - projected_speed
	if speed_remaining <= 0:
		return
	
	acceleration_final = acceleration * delta * top_speed
	clampf(acceleration_final, 0, speed_remaining)
	PLAYER.velocity.x += acceleration_final * direction_wish_to_go.x
	PLAYER.velocity.z += acceleration_final * direction_wish_to_go.z

# ==================== [Gravity] ====================
func handle_gravity(delta):
	if not PLAYER.is_on_floor():
		grounded = false
		air_move(delta)
		snap = Vector3.DOWN
		gravity_vector += Vector3.DOWN * gravity * delta
	if PLAYER.is_on_floor():
		snap = -PLAYER.get_floor_normal()
		gravity_vector = Vector3.ZERO
		if PLAYER.velocity.y > 10:
			grounded = false
			air_move(delta)
		else:
			grounded = true
			ground_move(delta)
	
	# Don't jump twice
	if PLAYER.is_on_floor() and jump_twice == true and not Input.is_action_pressed("jump") and Debug.auto_bunny_hopping == false:
		jump_twice = false
	if PLAYER.is_on_floor() and TrdP.landing_animation_on_fall == true:
		TrdP.mesh_3rd_animation.set("parameters/land_event/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		SOUNDS.fall.play()
		TrdP.landing_animation_on_fall = false

#region ---- Bug fixes ----------------
# Cap air speed to not pass the limit.
# This can be bad if I had cars or other object that push the player.
# It's a solid fix and not fluid, so crouching and uncrouching mid air is affected.
func cap_air_speed():
	if Debug.enable_bunny_hopping == true:
		return
	var horizontal_velocity = Vector3(PLAYER.velocity.x, 0, PLAYER.velocity.z)
	if horizontal_velocity.length() >= air_speed_cap:
		horizontal_velocity = horizontal_velocity.normalized() * air_speed_cap
		PLAYER.velocity.x = horizontal_velocity.x
		PLAYER.velocity.z = horizontal_velocity.z

# This makes the player speed 0 if it is less than 0.2.
# It's a bad way to fix a bug, it should be fixed from root, but this is the fastest fix.
# The root problem probably comes from apply_friction.
func lock_sliding_bug():
	if (Input.get_vector("left", "right", "forward", "backward")) != Vector2.ZERO:
		return
	if (( PLAYER.velocity * Vector3(0, 0, 1) ).length()) < 0.2: # It applies everytime with no input.
		PLAYER.velocity.z = 0

# Movement Jittery on Higher Framerate Fix - Interpolation
# Only works on X and Z axis because I can't seem to fix Y axis.
# It's also a solid way to fix it, a better way could be to rewrite the physics
# movement or just make the physic ticks larger than 60, but that's a bad fix.
func _movement_interpolation(delta):
	var fps = Engine.get_frames_per_second()
	var meshob = FstP.head
	var lerp_interval = head_end_position / fps
	var lerp_position = PLAYER.global_transform.origin + lerp_interval
	
	#if fps > 60:
	meshob.set_as_top_level(true)
	var lerp_xz = meshob.global_transform.origin.lerp(lerp_position, 50 * delta)
	meshob.position.x = lerp_xz.x
	meshob.position.z = lerp_xz.z
	var lerp_y = PLAYER.global_transform.origin + head_end_position # Head position bugs so I have to use default without "lerp"
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
			var transform3d: Transform3D = PLAYER.global_transform
			var motion: Vector3 = step_height
			
			var is_player_collided: bool = PhysicsServer3D.body_test_motion(PLAYER.get_rid(), params(transform3d, motion), test_motion_result)
			
			if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).y < 0:
				continue
				
			if not is_player_collided:
				transform3d.origin += step_height
				motion = PLAYER.velocity * delta
				is_player_collided = PhysicsServer3D.body_test_motion(PLAYER.get_rid(), params(transform3d, motion), test_motion_result)
				if not is_player_collided:
					transform3d.origin += motion
					motion = -step_height
					is_player_collided = PhysicsServer3D.body_test_motion(PLAYER.get_rid(), params(transform3d, motion), test_motion_result)
					if is_player_collided:
						if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(step_max_slope_degree):
							head_offset = -test_motion_result.get_remainder()
							is_step = true
							PLAYER.global_transform.origin += -test_motion_result.get_remainder()
							break
				else:
					var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal(0)
	
					transform3d.origin += test_motion_result.get_collision_normal(0) * wall_margin
					motion = (PLAYER.velocity * delta).slide(wall_collision_normal)
					is_player_collided = PhysicsServer3D.body_test_motion(PLAYER.get_rid(), params(transform3d, motion), test_motion_result)
					if not is_player_collided:
						transform3d.origin += motion
						motion = -step_height
						is_player_collided = PhysicsServer3D.body_test_motion(PLAYER.get_rid(), params(transform3d, motion), test_motion_result)
						if is_player_collided:
							if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(step_max_slope_degree):
								head_offset = -test_motion_result.get_remainder()
								is_step = true
								PLAYER.global_transform.origin += -test_motion_result.get_remainder()
								break
			else:
				var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal(0)
				transform3d.origin += test_motion_result.get_collision_normal(0) * wall_margin
				motion = step_height
				is_player_collided = PhysicsServer3D.body_test_motion(PLAYER.get_rid(), params(transform3d, motion), test_motion_result)
				if not is_player_collided:
					transform3d.origin += step_height
					motion = (PLAYER.velocity * delta).slide(wall_collision_normal)
					is_player_collided = PhysicsServer3D.body_test_motion(PLAYER.get_rid(), params(transform3d, motion), test_motion_result)
					if not is_player_collided:
						transform3d.origin += motion
						motion = -step_height
						is_player_collided = PhysicsServer3D.body_test_motion(PLAYER.get_rid(), params(transform3d, motion), test_motion_result)
						if is_player_collided:
							if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(step_max_slope_degree):
								head_offset = -test_motion_result.get_remainder()
								is_step = true
								PLAYER.global_transform.origin += -test_motion_result.get_remainder()
								break
	
	var is_falling: bool = false
	
	if not is_step and PLAYER.is_on_floor():
		var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		var step_height: Vector3 = step_height_default
		var transform3d: Transform3D = PLAYER.global_transform
		var motion: Vector3 = PLAYER.velocity * delta
		var is_player_collided: bool = PhysicsServer3D.body_test_motion(PLAYER.get_rid(), params(transform3d, motion), test_motion_result)
		
		if not is_player_collided:
			transform3d.origin += motion
			motion = -step_height
			is_player_collided = PhysicsServer3D.body_test_motion(PLAYER.get_rid(), params(transform3d, motion), test_motion_result)
			if is_player_collided:
				if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(step_max_slope_degree):
					head_offset = test_motion_result.get_travel()
					is_step = true
					PLAYER.global_transform.origin += test_motion_result.get_travel()
			else:
				is_falling = true
		else:
			if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).y == 0:
				var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal(0)
				transform3d.origin += test_motion_result.get_collision_normal(0) * wall_margin
				motion = (PLAYER.velocity * delta).slide(wall_collision_normal)
				is_player_collided = PhysicsServer3D.body_test_motion(PLAYER.get_rid(), params(transform3d, motion), test_motion_result)
				if not is_player_collided:
					transform3d.origin += motion
					motion = -step_height
					is_player_collided = PhysicsServer3D.body_test_motion(PLAYER.get_rid(), params(transform3d, motion), test_motion_result)
					if is_player_collided:
						if test_motion_result.get_collision_count() > 0 and test_motion_result.get_collision_normal(0).angle_to(Vector3.UP) <= deg_to_rad(step_max_slope_degree):
							head_offset = test_motion_result.get_travel()
							is_step = true
							PLAYER.global_transform.origin += test_motion_result.get_travel()
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

# ==================== [Noclip] ====================
func on_noclip(delta):
	if GAMEMENU.paused == true:
		PLAYER.velocity = Vector3.ZERO
		direction_wish_to_go = Vector3.ZERO
		return
	
	# Get the input direction
	direction_wish_to_go = Vector3.ZERO
	var camera_rotation: Basis = FstP.camera.global_transform.basis
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
		PLAYER.velocity.y += noclip_speed_now
	
	if Input.is_action_pressed("crouch"):
		PLAYER.velocity.y -= noclip_speed_now
	
	PLAYER.velocity += noclip_speed_now * direction_wish_to_go
	#velocity.x += noclip_speed_now * direction_wish_to_go.x
	#velocity.z += noclip_speed_now * direction_wish_to_go.z
	#velocity.y += noclip_speed_now * direction_wish_to_go.y
	
	#velocity.y += noclip_speed_now * clamp(camera_rotation.get_euler().x, -1.0, 1.0)
	
	TrdP._handle_3rd_person_animations(input_direction, delta)
