extends CanvasLayer

@onready var container = $MarginContainer
# Make sure this path matches the exact name of your RichTextLabel node!
@onready var subtitle_label = $MarginContainer/PanelContainer/SubtitleText 

var typing_speed: float = 0.04

func show_typewriter_text(text_to_type: String, duration_after_typing: float = 2.5):
	# 1. Show the UI layout container
	container.show()
	
	# 2. Assign the text and completely hide all characters initially
	subtitle_label.text = text_to_type
	subtitle_label.visible_characters = 0
	
	# 3. Type out each letter one by one
	while subtitle_label.visible_characters < text_to_type.length():
		subtitle_label.visible_characters += 1
		await get_tree().create_timer(typing_speed).timeout
		
	# 4. Wait for the player to read it AFTER it finishes typing
	await get_tree().create_timer(duration_after_typing).timeout
	
	# 5. Hide it until the next line is called
	container.hide()
