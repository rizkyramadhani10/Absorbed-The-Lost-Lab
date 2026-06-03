extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Step 4: Add the code for each button functionality

func _on_play_button_pressed() -> void:
	# This calls our global manager, fades out, switches the scene, and fades back in!
	TransitionScreen.transition_to_scene("res://scenes/game.tscn")


func _on_setting_button_pressed() -> void:
	# You can load a settings scene here, or toggle a settings panel visibility
	# Example if changing scenes:
	get_tree().change_scene_to_file("res://SettingsMenu.tscn")

func _on_logout_button_pressed() -> void:
	# This closes the game completely
	get_tree().quit()
