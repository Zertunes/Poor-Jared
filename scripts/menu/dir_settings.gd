extends Node

const user = "user://preferences.save"

var user_data = {}
var user_data_default = {}

func _ready():
	default_data()
	if not FileAccess.file_exists(user):
		var save_write = FileAccess.open(user, FileAccess.WRITE_READ)
		var json_string_save = JSON.stringify(default_data())
		save_write.store_string(json_string_save)
		
		while save_write.get_position() < save_write.get_length():
			var json_string = save_write.get_line()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			var file_result = json.get_data()
			user_data = file_result
		save_write.close()
		
		save_data()
	else:
		var save_read = FileAccess.open(user, FileAccess.READ)
		while save_read.get_position() < save_read.get_length():
			var json_string = save_read.get_line()
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			var file_result = json.get_data()
			user_data = file_result
		save_read.close()
		
		save_data()

func default_data():
	user_data_default = {
		"dev": 0,
		"discord": 1
		}
	if not FileAccess.file_exists(user):
		user_data = user_data_default

func save_data():
	var file = FileAccess.open(user, FileAccess.WRITE)
	var save = JSON.stringify(user_data)
	file.store_string(save)
