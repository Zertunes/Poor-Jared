extends Node

@export var PLAYER: CharacterBody3D
@export var HUD: Control
@export var MOVEMENT: Node
@onready var GAMEMENU = get_parent().get_parent().get_parent().get_node("GameMenu")

var stamina_points: float = 100
var run: bool = false
var run_ticking: bool = false
var stamina_recharge: bool = false
var stamina_loss: float = 1
var stamina_regain: float = 0.5
var sub_time = 5
var time_between_sub = sub_time
var time_between_sub2 = sub_time

func stamina():
	if stamina_points <= 0:
		stamina_points = 0
	if stamina_points >= 100:
		stamina_points = 100
	
	if (( PLAYER.velocity * Vector3(1, 0, 1) ).length()) == 0 or MOVEMENT.crouching_collision.disabled == false:
		run_ticking = false
	else:
		if Input.is_action_pressed("sprint"):
			if stamina_points >= 1:
				run = true
				run_ticking = true
				#print("a")
	
	if GAMEMENU.paused == false:
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
	if GlobalDebug.disable_run_ticking == true:
		stamina_points = 100
		HUD._stamina_label()
		return
	
	if run_ticking == true:
		if (( PLAYER.velocity * Vector3(1, 0, 1) ).length()) > 0:
			if MOVEMENT.crouching_collision.disabled == true:
				time_between_sub -= 1
				if time_between_sub <= 0:
					time_between_sub = sub_time
					stamina_points = stamina_points - stamina_loss
					stamina_recharge = false
					HUD._stamina_label()
					#print("stamina loss")
					if stamina_points <= 0:
						cant_run()
	else:
		if stamina_points < 100:
			if MOVEMENT.crouching_collision.disabled == false: # This was by accident but I actually like no delay then crouched
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
				HUD._stamina_label()
				#print("stamina recharge")
				if stamina_points <= 0:
					cant_run()

func cant_run():
	run = false
	run_ticking = false
	MOVEMENT.top_speed = MOVEMENT.top_speed_walking
	MOVEMENT.air_speed_cap = MOVEMENT.top_speed + MOVEMENT.speed_changer
	#air_speed_cap = top_speed_walking + 3
