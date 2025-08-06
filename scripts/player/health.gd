extends Node

@export var PLAYER: CharacterBody3D
@export var SOUNDS: Node
@export var HUD: Control
@export var TrdP: Node
@export var FstP: Node

@export var health_bar: TextureProgressBar
@export var health_bar_label: Label
@export var damage_vignette: TextureRect
@onready var damage_vignette_color = Color(1, 1, 1, 0)
@onready var dead = false
@onready var edelta = 0

# Health
@export var max_health: int = 100
var current_health: int = max_health

# Fall damage
@export var fall_distance_threshold: float = 5.0
@export var fall_damage_multiplier: float = 5.0
var fall_distance: float = 0.0
var was_on_floor: bool = true

signal health_changed(new_health)
signal player_died

@onready var ragdoll = preload("res://scenes/player/ragdoll.tscn")

func _ready():
	dead = false
	current_health = max_health
	_health_bar_update()
	damage_vignette.visible = true
	damage_vignette.modulate = damage_vignette_color

func _process(delta):
	#auto_bunny_hopping = GlobalDebug.get_auto_bunny_hopping()
	edelta = delta
	Debug.health = current_health
	if Debug.noclip: return
	player_fall_damage()

# Method to apply damage
func do_damage(amount: int):
	current_health -= amount
	SOUNDS.health_loss.play()
	SOUNDS.hurt_voice.play()
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
	if not PLAYER.is_on_floor():
		if PLAYER.velocity.y < 0:
			# Player is falling
			fall_distance += -PLAYER.velocity.y * edelta
		else:
			# Player is rising or moving horizontally
			if fall_distance > 0:
				# Player has landed after falling
				player_fall_damage_calculate()
				fall_distance = 0
	else:
		# Player is on the ground
		if not was_on_floor and fall_distance > 0:
			# Player has just landed
			player_fall_damage_calculate()
			fall_distance = 0
	was_on_floor = PLAYER.is_on_floor()

func player_fall_damage_calculate():
	# Calculate fall damage if it is a high place
	if fall_distance > fall_distance_threshold:
		var damage = (fall_distance - fall_distance_threshold) * fall_damage_multiplier
		# Apply fall damage to the player
		SOUNDS.fall_damage.play()
		do_damage(damage)
		# Remove speed
		PLAYER.velocity = Vector3(0, 0, 0)
		# Reset fall distance
		fall_distance = 0

func _health_bar_update():
	health_bar_label.text = str(current_health) + "%"
	#health_bar.value = current_health
	get_tree().create_tween().tween_property(health_bar, "value", current_health, 0.5).set_trans(Tween.TRANS_SINE)

# ==================== [Health] ====================
func connect_health_component():
	player_died.connect(_on_player_died)
	health_changed.connect(_on_health_changed)
func _on_player_died():
	#print("Player has died")
	#health.do_damage(20)
	HUD.deathmenu.background.show()
	HUD.deathmenu.death_menu.show()
	TrdP.mesh.hide()
	FstP.view_model_rig.visible = false
	
	SOUNDS.death_voice.play()
	
	# Instantiate the ragdoll scene and set its position to the player's current position
	var ragdoll_instance = ragdoll.instantiate()
	ragdoll_instance.global_transform = PLAYER.global_transform
	get_parent().add_child(ragdoll_instance)
func _on_health_changed(new_health):
	#print("Health changed to: ", new_health)
	pass
