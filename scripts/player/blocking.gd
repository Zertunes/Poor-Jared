extends Node

var PLAYER: CharacterBody3D = get_parent()
@export var SOUNDS: Node
@export var TrdP: Node

@export var BlockIKTime: Timer
@onready var blocking: bool = false
@onready var blocked_hits: int = 0
@onready var block_stun_timer: Timer
@onready var is_stunned: bool = false
@export var max_block_hits: int = 3
@export var block_start_delay: float = 0.5
@export var block_cooldown: float = 1.0

func _process(delta):
	if Input.is_action_pressed("defend") and !blocking:
		_on_block_ik_time_timeout()  # Start blocking after delay
	elif Input.is_action_just_released("defend") and blocking:
		stop_blocking()  # Stop blocking when releasing right-click

func start_blocking():
	if is_stunned:
		return  # Can't block while stunned
	blocking = true
	SOUNDS.block.play()  # Play blocking sound
	TrdP.mesh_3rd_animation.set("parameters/block_event/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	BlockIKTime.start()

# Stop defending
func stop_blocking():
	blocking = false
	TrdP.mesh_3rd_animation.set("parameters/block_event/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)

# Handle getting hit while blocking
func on_hit_while_blocking():
	if blocking:
		blocked_hits += 1
		SOUNDS.block_impact.play()  # Play impact sound
		if blocked_hits >= max_block_hits:
			get_unblocked()

# Become unblocked and stunned
func get_unblocked():
	blocking = false
	is_stunned = true
	SOUNDS.stun.play()  # Play stun sound
	block_stun_timer.start(block_cooldown)
	TrdP.mesh_3rd_animation.set("parameters/stun_event/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
# Exit stun state
func exit_stun():
	is_stunned = false
	blocked_hits = 0

# Connect timer to exit stun after cooldown
func _on_block_stun_timer_timeout():
	exit_stun()

# Connect block start delay to the defense start
func _on_block_ik_time_timeout():
	start_blocking()
