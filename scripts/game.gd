extends Node2D

func _ready():
	# Wait for the scene to load...
	await get_tree().create_timer(1.0).timeout
	
	# Call the typewriter effect on your subtitle label
	SubtitleUi.show_typewriter_text("Where... am I? This looks like an old examination room.")
