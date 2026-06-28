extends Area2D

@export_file("*.tscn") var target_scene_path: String

@onready var interaction_hint = $Label
@onready var sfx_player = $AudioStreamPlayer2D # 1. Reference the audio player node

var player_nearby: bool = false

func _ready() -> void:
	interaction_hint.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("interact"):
		if target_scene_path != "":
			player_nearby = false 
			interaction_hint.visible = false
			
			# 2. Play the door opening sound here!
			sfx_player.play()
			
			# 3. Start the transition screen sequence
			TransitionScreen.transition_to_scene(target_scene_path)
		else:
			print("Warning: No target scene path set for this door!")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = true
		interaction_hint.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = false
		interaction_hint.visible = false
