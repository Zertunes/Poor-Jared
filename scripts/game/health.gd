extends Node

@onready var player = $".."
@onready var health_bar = $"../Control/HealthBar"
@onready var health_bar_label = $"../Control/HealthBar/Label"
@onready var damage_vignette = $"../Body/Head/Tilt/Damage Vignette"
@onready var damage_vignette_color = Color(1, 1, 1, 0)
@onready var dead = false
@onready var edelta = 0

# Health
@export var max_health: int = 100
var current_health: int = max_health

# Fall damage
var fallDistanceThreshold = 1
var fallDamageMultiplier = 15   # Adjust this value for the damage multiplier
var fallDistance = 0

signal health_changed(new_health)
signal player_died

func _ready():
	dead = false
	current_health = max_health
	_health_bar_update()
	damage_vignette.visible = true
	damage_vignette.modulate = damage_vignette_color

func _process(delta):
	#auto_bunny_hopping = GlobalDebug.get_auto_bunny_hopping()
	edelta = delta
	pass

# Method to apply damage
func do_damage(amount: int):
	current_health -= amount
	$"../HealthLoss".play()
	$"../PlayerHurtVoice".play()
	if current_health <= 0:
		dead = true
		emit_signal("player_died")
		current_health = 0  # Ensure health doesn't go below 0
	emit_signal("health_changed", current_health)
	_health_bar_update()
	
	# Animation
	if current_health >= 35:
		damage_vignette_color = Color(1, 1, 1, 0.6)
	else:
		damage_vignette_color = Color(1, 1, 1, 1)
	get_tree().create_tween().tween_property(damage_vignette, "modulate", damage_vignette_color, 0.2).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(1).timeout
	if current_health <= 60:
		damage_vignette_color = Color(1, 1, 1, 0.5)
	elif current_health <= 30:
		damage_vignette_color = Color(1, 1, 1, 0.7)
	elif current_health <= 15:
		damage_vignette_color = Color(1, 1, 1, 1)
	elif current_health == 0:
		damage_vignette_color = Color(1, 1, 1, 1)
	else:
		damage_vignette_color = Color(1, 1, 1, 0)
	get_tree().create_tween().tween_property(damage_vignette, "modulate", damage_vignette_color, 2).set_trans(Tween.TRANS_SINE)

# Method to heal
func do_heal(amount: int):
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	emit_signal("health_changed", current_health)
	_health_bar_update()
	
	# Animation
	damage_vignette_color = Color(0, 255, 0, 0.5)
	get_tree().create_tween().tween_property(damage_vignette, "modulate", damage_vignette_color, 1).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(1).timeout
	
	damage_vignette_color = Color(0, 255, 0, 0)
	get_tree().create_tween().tween_property(damage_vignette, "modulate", damage_vignette_color, 1).set_trans(Tween.TRANS_SINE)

# Method for fall damage
func player_fall_damage():
	# Check if the player is falling
	if not player.is_on_floor() and player.velocity.y < 0:
		# Accumulate fall distance
		fallDistance += -player.velocity.y * edelta
		#print(fallDistance)
	else:
		player_fall_damage_calculate()
		fallDistance = 0

func player_fall_damage_calculate():
	# Calculate fall damage if it is a high place
	if fallDistance > fallDistanceThreshold:
		var damage = (fallDistance - fallDistanceThreshold) * fallDamageMultiplier
		# Apply fall damage to the player
		$"../FallDamage".play()
		do_damage(damage)
		# Remove speed
		player.velocity = Vector3(0, 0, 0)
		# Reset fall distance
		fallDistance = 0

func _health_bar_update():
	health_bar_label.text = str(current_health) + "%"
	#health_bar.value = current_health
	get_tree().create_tween().tween_property(health_bar, "value", current_health, 0.5).set_trans(Tween.TRANS_SINE)
