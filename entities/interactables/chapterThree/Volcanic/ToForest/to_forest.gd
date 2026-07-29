extends Area2D

@export_file("*.tscn") var target_scene_path: String

# Tambahan baru
@export var target_spawn: String = ""

@onready var interaction_hint = $Label

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

			# Simpan nama spawn yang akan dipakai di scene berikutnya
			Global.spawn_point = target_spawn

			TransitionScreen.transition_to_scene(target_scene_path)

		else:
			print("Warning: No target scene path set!")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = true
		interaction_hint.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = false
		interaction_hint.visible = false
