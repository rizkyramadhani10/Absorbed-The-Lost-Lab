extends Area2D

@export_file("*.tscn") var target_scene_path: String
@export var target_spawn: String = ""

# 📄 Path file resource dialog locked .tres
@export_file("*.tres") var locked_dialog_path: String = ""

@onready var interaction_hint = $Label
@onready var sfx_player = $AudioStreamPlayer2D

var player_nearby: bool = false
var player_ref: Node2D = null
var is_dialog_playing: bool = false

func _ready() -> void:
	if interaction_hint:
		interaction_hint.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("interact") and not is_dialog_playing:

		# 🔒 CEK PROGRESS CERITA: Harus pakai APD dulu
		if not Global.has_apd:
			_play_locked_dialog()
			return

		# 🚪 JIKA SUDAH PAKAI APD -> PROSES PINDAH SCENE
		if target_scene_path != "":
			player_nearby = false
			if interaction_hint:
				interaction_hint.visible = false

			Global.spawn_point = target_spawn
			
			Global.player_last_position = Vector2.ZERO 
			Global.player_last_flip = false
			
			if sfx_player:
				sfx_player.play()

			TransitionScreen.transition_to_scene(target_scene_path)
		else:
			print("Warning: No target scene path set!")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = true
		player_ref = body
		if interaction_hint:
			interaction_hint.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = false
		player_ref = null
		if interaction_hint:
			interaction_hint.visible = false

# 💬 Fungsi memunculkan dialog pada Player
func _play_locked_dialog() -> void:
	if locked_dialog_path == "":
		print("ERROR di Door: 'Locked Dialog Path' di Inspector masih KOSONG!")
		return

	if player_ref == null:
		return

	var dp = player_ref.get_node_or_null("DialogPlayer")
	if dp == null:
		dp = player_ref.find_child("DialogPlayer", true, false)

	if dp == null:
		print("ERROR di Door: Node 'DialogPlayer' tidak ditemukan pada " + player_ref.name)
		return

	is_dialog_playing = true

	# 1. Kunci pergerakan & input player
	player_ref.set_physics_process(false)
	if player_ref.has_method("set_process_unhandled_input"):
		player_ref.set_process_unhandled_input(false)

	# 2. Assign resource & jalankan dialog
	var dialogue_resource = load(locked_dialog_path)
	dp._dialog_data = dialogue_resource
	dp.start()

	await dp.dialog_ended

	# 3. Kembalikan kontrol player
	player_ref.set_physics_process(true)
	if player_ref.has_method("set_process_unhandled_input"):
		player_ref.set_process_unhandled_input(true)

	is_dialog_playing = false
