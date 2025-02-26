extends Node

@export var PLAYER: CharacterBody3D
@export var HEALTH: Node

@rpc("unreliable","any_peer","call_local") func update_position(id, u_position, u_motion_mode, u_mesh, u_camera):
	if is_multiplayer_authority(): return
	if name != id: return
	PLAYER.position = lerp(PLAYER.position, u_position, PLAYER.edelta * 50)
	PLAYER.motion_mode = lerp(PLAYER.motion_mode, u_motion_mode, PLAYER.edelta * 10)
	PLAYER.mesh.rotation = u_mesh # This can't be lerped (lerp bug then lerping rotations)
	PLAYER.camera.rotation.x = lerp(PLAYER.camera.rotation.x, u_camera, PLAYER.edelta * 30)

@rpc("unreliable","any_peer","call_local") func update_animation(id, u_animation_player, u_animation_tree, u_head_ik, parameter_crouch, parameter_crouched, parameter_jump, parameter_land, parameter_walking, u_landing, crouched_time_scale, walking_time_scale):
	if is_multiplayer_authority(): return
	if name != id: return
	PLAYER.mesh_3rd_animation_player.current_animation = u_animation_player
	PLAYER.mesh_3rd_animation.anim_player = u_animation_tree
	PLAYER.rotate_x_looking_animation_ik.interpolation = u_head_ik
	PLAYER.mesh_3rd_animation["parameters/crouch_event/blend_amount"] = parameter_crouch
	PLAYER.mesh_3rd_animation["parameters/crouched/blend_position"] = parameter_crouched
	PLAYER.mesh_3rd_animation["parameters/jump_event/request"] = parameter_jump
	PLAYER.mesh_3rd_animation["parameters/land_event/request"] = parameter_land
	PLAYER.mesh_3rd_animation["parameters/walking/blend_position"] = parameter_walking
	PLAYER.landing_animation_on_fall = u_landing
	PLAYER.mesh_3rd_animation["parameters/crouched_time_scale/scale"] = crouched_time_scale
	PLAYER.mesh_3rd_animation["parameters/walking_time_scale/scale"] = walking_time_scale

@rpc("unreliable","any_peer","call_local") func update_attack(id, parameter_attack, parameter_attack_crouch, u_attacking):
	if is_multiplayer_authority(): return
	if name != id: return
	PLAYER.mesh_3rd_animation["parameters/attack_event/request"] = parameter_attack # Attack animation
	PLAYER.mesh_3rd_animation["parameters/attack_event_crouch/request"] = parameter_attack_crouch # Attack animation
	PLAYER.attacking = u_attacking # Yeah, uh, the IK thingy

func _on_player_tickrate_timeout():
	if !is_multiplayer_authority(): return
	rpc("update_position", name, PLAYER.position, PLAYER.motion_mode, PLAYER.mesh.rotation, PLAYER.camera.rotation.x)
	rpc("update_animation", name, PLAYER.mesh_3rd_animation_player.current_animation, PLAYER.mesh_3rd_animation.anim_player, PLAYER.rotate_x_looking_animation_ik.interpolation, PLAYER.mesh_3rd_animation["parameters/crouch_event/blend_amount"], PLAYER.mesh_3rd_animation["parameters/crouched/blend_position"], PLAYER.mesh_3rd_animation["parameters/jump_event/request"], PLAYER.mesh_3rd_animation["parameters/land_event/request"], PLAYER.mesh_3rd_animation["parameters/walking/blend_position"], PLAYER.landing_animation_on_fall, PLAYER.mesh_3rd_animation["parameters/crouched_time_scale/scale"], PLAYER.mesh_3rd_animation["parameters/walking_time_scale/scale"])
	rpc("update_attack", name, PLAYER.mesh_3rd_animation["parameters/attack_event/request"], PLAYER.mesh_3rd_animation["parameters/attack_event_crouch/request"], PLAYER.attacking)

@rpc("any_peer") func receive_damage():
	HEALTH.do_damage(10)
