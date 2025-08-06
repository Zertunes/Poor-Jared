extends OptionButton

# This function will update the UI elements when the language changes
func _ready():
	var parent = str(get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()).split(":")[0].strip_edges()
	if parent != "GameMenu":
		get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().player_created.connect(load_button)
		#return
	
	LanguageManager.language_change.connect(load_button)
	
	if SaveOptions.game_options_data:
		if SaveOptions.game_options_data.language != OS.get_locale():
			LanguageManager.change_language(SaveOptions.game_options_data.language)
	
	load_button()

func language_button():
	# Clear previous items
	clear()
	
	# Add all available languages to the OptionButton
	for language_info in LanguageManager.languages.values():
		add_item(language_info["name"])  # Add language names as options
		set_item_tooltip(get_item_count() - 1, TranslationServer.translate("by") + " " + language_info["translator"])  # Set tooltip

func load_button():
	language_button()
	
	# Set the current selected language
	var current_locale = OS.get_locale()  # Get current locale
	var selected_index = -1
	
	if SaveOptions.game_options_data:
		if SaveOptions.game_options_data.language != current_locale:
			#LanguageManager.change_language(SaveOptions.game_options_data.language)
			current_locale = SaveOptions.game_options_data.language
	
	# Search for the matching language name in the OptionButton list
	# This first one is to find specific locale (ex. en_US)
	#for i in range(get_item_count()):
		#for language_info in LanguageManager.languages.values():
			#if language_info["name"] == get_item_text(i):
				#if language_info["locale"] == current_locale:
					#selected_index = i
					#break
	# If there is no perfect match, then it looks for only the language (ex. en) [BUT ONLY IF THERE WAS NO PERFECT MATCH AFTER LOOKING AT EVERY LANGUAGE] (The code is commented because I prefer on having one language per many regions other than many regions (ex. pt other than pt_PT and pt_BR))
	if selected_index == -1:
		for i in range(get_item_count()):
			for language_info in LanguageManager.languages.values():
				if language_info["name"] == get_item_text(i):
					if language_info["locale"] == current_locale.split("_")[0].strip_edges():
						selected_index = i
						break
	select(selected_index)  # Set the selected language

# This function will be called when an option is selected from the OptionButton
func _on_item_selected(index: int) -> void:
	var selected_language_name = get_item_text(index)  # Get selected language name
	for language_info in LanguageManager.languages.values():
		if language_info["name"] == selected_language_name:
			LanguageManager.change_language(language_info["locale"])  # Change the language
			break
