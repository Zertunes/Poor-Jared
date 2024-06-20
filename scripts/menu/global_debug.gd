extends Node

@export var auto_bunny_hopping: bool = false
@export var enable_bunny_hopping: bool = false
@export var disable_run_ticking: bool = false
@export var noclip: bool = false

func _ready():
	if has_node(PankuConsole.SingletonPath):
		var console: PankuConsole = get_node(PankuConsole.SingletonPath)
		console.gd_exprenv.register_env('debug', self)
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
