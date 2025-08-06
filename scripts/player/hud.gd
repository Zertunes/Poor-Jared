extends Control

@export var PLAYER: CharacterBody3D
@export var STAMINA: Node

@export var speed_label: Label
@export var fps_label: Label
@export var stamina_bar: TextureProgressBar
@export var vignette: TextureRect
@export var reticle: CenterContainer

# Time
@onready var world_env = get_parent().get_parent().get_parent().get_node("WorldEnvironment")
@export var time: Label
@export var day_count: Label

# Death
@onready var deathmenu = {
	"death_menu": $deathmenu/DeathMenu,
	"background": $deathmenu/DeathMenu/Background,
}

# ==================== [Labels] ====================
func _speed_label(): # Can be found in _physics_process()
	speed_label.text = str( int( ( PLAYER.velocity * Vector3(1, 0, 1) ).length() ) )

func _fps_label(): # Can be found in _progress()
	fps_label.text = "FPS: %s" % [Engine.get_frames_per_second()]

func _stamina_label(): # Can be found in _run_ticking()
	stamina_bar.value = STAMINA.stamina_points
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

# ==================== [World] ====================
func connect_world_env_component():
	if world_env == null: return
	world_env.hour_changed.connect(_on_hour_changed)
	world_env.day_changed.connect(_on_day_changed)
func _on_hour_changed(hour, space):
	var signature
	if space:
		signature = TranslationServer.translate("day.morning")
	else:
		signature = TranslationServer.translate("day.evening")
	time.text = str(hour) + " " + signature
func _on_day_changed(day):
	day_count.text = TranslationServer.translate("day") + " " + str(day)
