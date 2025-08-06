extends Node

func discord_presence():
	if not Preferences.user_data.discord: return
	discord_sdk.app_id = 1165719657815220296 # Application ID
	discord_sdk.details = "In The Main Menu"
	#discord_sdk.state = "Yes, I'm making a game in Godot."
	
	discord_sdk.large_image = "poorjared_singleplayer" # Image key from "Art Assets"
	#discord_sdk.large_image = "placeholder" # Image key from "Art Assets"
	#discord_sdk.large_image_text = "YOOO! Wait, you saw this?"
	#discord_sdk.small_image = "placeholder_small" # Image key from "Art Assets"
	#discord_sdk.small_image_text = "Among us???"
	
	discord_sdk.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
	# discord_sdk.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00 remaining"
	
	discord_sdk.refresh() # Always refresh after changing the values!

func multi():
	if not Preferences.user_data.discord: return
	discord_sdk.details = "Playing Multiplayer"
	discord_sdk.large_image = "poorjared_multiplayer"
	discord_sdk.refresh()

func single():
	if not Preferences.user_data.discord: return
	discord_sdk.details = "Playing Singleplayer"
	discord_sdk.large_image = "poorjared_yee"
	discord_sdk.refresh()

func menu():
	if not Preferences.user_data.discord: return
	discord_sdk.details = "In The Main Menu"
	discord_sdk.large_image = "poorjared_singleplayer"
	discord_sdk.refresh()
