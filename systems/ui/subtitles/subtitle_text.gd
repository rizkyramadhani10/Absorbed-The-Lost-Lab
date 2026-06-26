extends RichTextLabel

# This variable controls the speed of the typing (lower is faster).
# You can change this to find the best speed for your game's tone.
var typing_speed = 0.05

func show_typewriter_text(new_text):
	# 1. Store the final text
	text = new_text
	
	# 2. Reset the label so it shows nothing (visible_characters = 0)
	visible_characters = 0
	
	# 3. Use a loop to type each character one by one
	while visible_characters < text.length():
		visible_characters += 1
		
		# This await command pauses the function briefly between each character,
		# creating the typewriter effect without freezing the rest of your game.
		await get_tree().create_timer(typing_speed).timeout

	# Optional: A short pause here before the subtitle starts fading away
	# await get_tree().create_timer(1.0).timeout
