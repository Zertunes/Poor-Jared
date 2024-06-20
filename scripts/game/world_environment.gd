extends WorldEnvironment

func _ready():
	environment.adjustment_enabled = true
	GlobalOptions.bloom_toggled.connect(_on_bloom_toggled)
	GlobalOptions.brightness_updated.connect(_on_brightness_updated)

func _on_bloom_toggled(value):
	environment.glow_enabled = value

func _on_brightness_updated(value):
	environment.adjustment_brightness = value
