extends Node

@export var auto_bunny_hopping: bool = false
@export var enable_bunny_hopping: bool = false
@export var disable_run_ticking: bool = false
@export var noclip: bool = false
var just_start_noclip: bool = true # on Player.gd
@export var health: int = 100
@export var hide_hud: bool = false

func _ready():
	if has_node(PankuConsole.SingletonPath):
		var console: PankuConsole = get_node(PankuConsole.SingletonPath)
		console.gd_exprenv.register_env('debug', self)
		console.gd_exprenv.register_env('cheats', self)
		console.gd_exprenv.register_env('c', self)

func get_auto_bunny_hopping() -> bool:
	return auto_bunny_hopping

func get_enable_bunny_hopping() -> bool:
	return enable_bunny_hopping

func get_disable_run_ticking() -> bool:
	return disable_run_ticking

func get_noclip() -> bool:
	return noclip

func kill():
	pass

func set_health() -> int:
	return health

func get_hud():
	return hide_hud

# ==================== [Debug] ====================
func debug_checker():
	auto_bunny_hopping = Debug.get_auto_bunny_hopping()
	enable_bunny_hopping = Debug.get_enable_bunny_hopping()
	disable_run_ticking = Debug.get_disable_run_ticking()
	noclip = Debug.get_noclip()
	health = Debug.set_health()
	hide_hud = Debug.get_hud()

func _print(arg1 = null, arg2 = null, arg3 = null, arg4 = null, arg5 = null, arg6 = null, arg7 = null, arg8 = null, arg9 = null):
	var array = []
	for argument in [arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9]:
		if argument != null:
			array.push_back(argument)
	if Preferences.user_data.debug:
		print("".join(array.map(func(a): return str(a))))
