extends Node

signal language_change

@export var languages_folder_path: String = "res://localization/"
@export var public_languages_folder_path: String = "user://localization/"

var languages: Dictionary = {}

func _ready():
	load_languages(languages_folder_path)
	load_languages(public_languages_folder_path)

# Loads all available languages from the 'localization' folder
func load_languages(folder_path: String):
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()  # Start reading the directory
		var file = dir.get_next()  # Get the first file
		while file:
			if file.ends_with(".lang"):
				var lang_file_path = languages_folder_path + file
				var lang_file = FileAccess.open(lang_file_path, FileAccess.READ)
				if lang_file:
					var content = lang_file.get_as_text()
					var language_info = get_language_from_file(content)
					if language_info:
						languages[lang_file_path] = language_info
						Debug._print("Loading language: ", language_info["name"])  # Debugging log
						add_language_translation(lang_file_path, language_info)
					lang_file.close()
			file = dir.get_next()  # Get the next file
		dir.list_dir_end()  # End directory reading

# Extracts the language name from the file content (e.g., 'language=English')
func get_language_from_file(content: String) -> Dictionary:
	var regex = RegEx.new()
	if regex.compile("language=([^\n]+)\nlocale=([^\n]+)\ntranslator=([^\n]+)") == OK:
		var result = regex.search(content, 0)  # Starting at position 0
		if result:
			return {
				"name": result.get_string(1).strip_edges(),
				"locale": result.get_string(2).strip_edges(),
				"translator": result.get_string(3).strip_edges(),
			}
	return {}

func add_language_translation(language_path: String, language_info: Dictionary):
	var lang_file = FileAccess.open(language_path, FileAccess.READ)
	if lang_file:
		var translation = Translation.new()
		var content = lang_file.get_as_text()
		
		# Parse the language content into key-value pairs
		var lines = content.split("\n")
		for line in lines:
			if line.strip_edges() != "":
				var parts = line.split("=")
				if parts.size() == 2:
					var key = parts[0].strip_edges()
					var value = parts[1].strip_edges()
					translation.add_message(key, value)  # Add each translation key-value pair
		
		# Set the locale for this translation
		translation.set_locale(language_info["locale"])  # Set the locale to the correct one
		
		# Add the translation to the TranslationServer
		TranslationServer.add_translation(translation)  # This adds the translation for the current language

# Changes the language in TranslationServer
func change_language(language_code: String) -> void:
	Debug._print("Setting locale to: ", language_code)
	TranslationServer.set_locale(language_code)
	SaveOptions.game_options_data.language = language_code
	SaveOptions.save_data()
	emit_signal("language_change")
