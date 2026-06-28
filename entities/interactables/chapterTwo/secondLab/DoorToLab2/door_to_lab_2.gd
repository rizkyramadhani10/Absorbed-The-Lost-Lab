extends Area2D

@export_file("*.tscn") var target_scene_path: String

@onready var door_sprite = $DoorToLab2
@onready var dim_overlay = $DimOverlay
@onready var interaction_hint = $Label
@onready var sfx_player = $AudioStreamPlayer2D

var player_nearby: bool = false
var fade_tween: Tween

func _ready() -> void:
	# Start-up conditions: Hint hidden, door barely visible, room normal
	interaction_hint.visible = false
	door_sprite.modulate.a = 0.15   # Lower opacity when far away
	dim_overlay.modulate.a = 0.0    # Completely transparent overlay
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("interact"):
		if target_scene_path != "":
			player_nearby = false 
			interaction_hint.visible = false
			
			if sfx_player:
				sfx_player.play()
				
			TransitionScreen.transition_to_scene(target_scene_path)
		else:
			print("Warning: No target scene path set for Lab 2 door!")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = true
		interaction_hint.visible = true
		
		# Smoothly reveal door and darken the rest of the world
		_animate_environment(1.0, 0.65) # Door to full visibility, overlay to 65% dark

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = false
		interaction_hint.visible = false
		
		# Smoothly fade the door back out and clear the screen dimming
		_animate_environment(0.15, 0.0)

# Helper function to handle smooth fading transitions
func _animate_environment(door_alpha: float, overlay_alpha: float) -> void:
	# Kill any running tween to prevent visual stuttering if the player steps in/out quickly
	if fade_tween:
		fade_tween.kill()
		
	fade_tween = create_tween().set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Animate both properties over 0.5 seconds
	fade_tween.tween_property(door_sprite, "modulate:a", door_alpha, 0.5)
	fade_tween.tween_property(dim_overlay, "modulate:a", overlay_alpha, 0.5)
