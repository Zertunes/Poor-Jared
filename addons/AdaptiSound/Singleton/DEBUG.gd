extends Node

func _print(value):
	if AudioManager.debugging:
		if Preferences.user_data.debug:
			print(value)
