extends Node

@export var PLAYER: CharacterBody3D
@export var HEALTH: Node

@export var fall_damage: AudioStreamPlayer
@export var punch: AudioStreamPlayer
@export var hurt_voice: AudioStreamPlayer
@export var health_loss: AudioStreamPlayer
@export var death_voice: AudioStreamPlayer
@export var steps: AudioStreamPlayer
@export var fall: AudioStreamPlayer
@export var jump: AudioStreamPlayer
@export var steps_timer: Timer

# Footstep sound parameters
var min_step_interval = 0.3  # Minimum interval between steps
var max_step_interval = 1.0  # Maximum interval for slow walking

func footstepsthingy():
	# Calculate the player's speed
	var speed = int((PLAYER.velocity * Vector3(1, 0, 1)).length())
	
	# Set the timer interval based on speed (higher speed = shorter interval)
	if PLAYER.is_on_floor() or HEALTH.dead:
		if speed > 0:
			var interval = lerp(max_step_interval, min_step_interval, speed / 10.0) # The float here is the player's max speed
			steps_timer.wait_time = interval
			if steps_timer.is_stopped():
				steps_timer.start()
		else:
			steps_timer.stop()
	else:
		steps_timer.stop()

# Define the function to play the footstep sound
func _on_steps_timer_timeout():
	steps.play()
