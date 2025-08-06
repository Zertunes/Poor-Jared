extends WorldEnvironment

signal hour_changed(hour, space)
signal day_changed(day)

@onready var game_menu = get_parent().get_node("GameMenu") #$GameMenu
@onready var city = get_parent()

var shader_material : ShaderMaterial = load("res://shader/world_environment.tres")
var time : float = 0.0
var day_length : float = 300.0  # Time for a full cycle in seconds

var hour : int = 6
var day : int = 0
var in_game_hour : int = 6
#var total_elapsed_time : float = 0.0
#var last_hour_update : float = 0.0
var has_day_changed : bool = false

func _ready():
	environment.adjustment_enabled = true
	Options.bloom_toggled.connect(_on_bloom_toggled)
	Options.brightness_updated.connect(_on_brightness_updated)
	LanguageManager.language_change.connect(update_language)
	if city == preload("res://scenes/world/test/test.tscn"): return
	city.night = false

func _on_bloom_toggled(value):
	environment.glow_enabled = value

func _on_brightness_updated(value):
	environment.adjustment_brightness = value

func _process(delta: float) -> void:
	if game_menu.joinlobby: return
	if city == preload("res://scenes/world/test/test.tscn"): return
	update_environment_properties(delta)

func update_time_properties():
	# Calculate hour based on time
	hour = int(24 * time) + 6  # Start the day at 6 AM
	
	if hour >= 30:
		hour = 6
	
	if hour >= 6 and hour <= 24:
		in_game_hour = hour
	elif hour == 25:
		in_game_hour = 1
	elif hour == 26:
		in_game_hour = 2
	elif hour == 27:
		in_game_hour = 3
	elif hour == 28:
		in_game_hour = 4
	elif hour == 29:
		in_game_hour = 5
	
	# Ensure hour wraps around correctly
	if in_game_hour >= 24 and not has_day_changed:
		day += 1
		emit_signal("day_changed", day)
		has_day_changed = true
	
	if in_game_hour < 24:
		has_day_changed = false
	
	var space
	var in_game_hour_share : int
	if in_game_hour > 12:
		space = false
		in_game_hour_share = in_game_hour - 12
		emit_signal("hour_changed", in_game_hour_share, space)
	else:
		space = true
		in_game_hour_share = in_game_hour
		emit_signal("hour_changed", in_game_hour_share, space)
	
	#print("hour: " + str(hour))
	#print("hour_in_game: " + str(in_game_hour))
	#print("day: " + str(day))

func update_language():
	emit_signal("day_changed", day)
	var space
	var in_game_hour_share : int
	if in_game_hour > 12:
		space = false
		in_game_hour_share = in_game_hour - 12
		emit_signal("hour_changed", in_game_hour_share, space)
	else:
		space = true
		in_game_hour_share = in_game_hour
		emit_signal("hour_changed", in_game_hour_share, space)

func update_environment_properties(delta):
	if shader_material:
		time += delta / day_length
		#total_elapsed_time += delta / day_length
		if time >= 1.0:
			time = 0.0
		shader_material.set_shader_parameter("time", time)
		
		update_time_properties()  # Sync hour with time
		
		if time < 0.021 and time >= 0:
			# Sunset to Day
			update_fog_properties(Color(0.957, 0.78, 0.525), 0.05, 1)
		elif time < 0.51 and time > 0.021:
			# Day
			update_fog_properties(Color(0.471, 0.875, 1), 0.004, 3)
		elif time < 0.52 and time > 0.51:
			# Sunset to Night
			update_fog_properties(Color(0, 0, 0), 0.1, 1)
		elif time < 0.98 and time > 0.52:
			# Night
			update_fog_properties(Color(0, 0, 0), 0.1, 1)
			city.night = true
		elif time <= 1 and time > 0.98:
			# Night to Sunset to Day
			update_fog_properties(Color(0.957, 0.78, 0.525), 0.05, 1)
			city.night = false
		
		## Update hour based on total elapsed time
		#if total_elapsed_time - last_hour_update >= 1.0 / 24.0:
			#last_hour_update = total_elapsed_time
			#update_time_properties()

func update_fog_properties(color: Color, density: float, duration: float):
	var tween = get_tree().create_tween()
	tween.tween_property(environment, "fog_light_color", color, duration)
	tween.tween_property(environment, "fog_density", density, duration)
