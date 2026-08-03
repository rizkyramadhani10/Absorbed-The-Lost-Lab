extends Node2D

# 🏷️ Struktur data untuk memetakan Stage Cerita ke File Dialog
@export var story_dialogs: Array[StoryDialogConfig] = []
@export var player: Node2D

func _ready() -> void:
	# 1. Dengarkan perubahan stage di masa mendatang
	GameState.stage_changed.connect(_on_stage_changed)
	
	# 2. Tunggu 1 frame agar Player dan scene ter-setup sempurna
	await get_tree().process_frame
	
	# 3. Cek stage yang sedang aktif saat ini (untuk menangkap stage dari scene sebelumnya)
	_check_and_trigger_dialog(GameState.current_stage)

func _on_stage_changed(new_stage: GameState.StoryStage) -> void:
	_check_and_trigger_dialog(new_stage)

func _check_and_trigger_dialog(target_stage: GameState.StoryStage) -> void:
	# Cari konfigurasi dialog yang cocok dengan stage saat ini
	for config in story_dialogs:
		if config.target_stage == target_stage and not config.has_played:
			config.has_played = true # Tandai agar tidak diputar berulang kali
			trigger_dialog(config.dialog_path, config.start_id)
			break

func trigger_dialog(dialog_path: String, start_id: int = 1) -> void:
	if player == null:
		print("ERROR di LevelManager: Node Player belum di-assign di Inspector!")
		return
		
	var dp = player.find_child("DialogPlayer", true, false)
	if dp and dialog_path != "":
		
		# 🔥 PENGAMAN: Beri jeda 1 frame agar Sprouty dan Scene sempat mendaftarkan Anchor (seperti 'xeno' atau 'xeno_left')
		# Sangat penting saat dialog dipicu tepat setelah scene load atau transisi minigame!
		await get_tree().process_frame
		
		# 1. Kunci pergerakan player
		player.set_physics_process(false)
		if player.has_method("set_process_unhandled_input"):
			player.set_process_unhandled_input(false)
			
		# 2. Putar dialog
		dp._dialog_data = load(dialog_path)
		dp.start()
		
		await dp.dialog_ended
		
		# 3. Kembalikan kontrol player
		player.set_physics_process(true)
		if player.has_method("set_process_unhandled_input"):
			player.set_process_unhandled_input(true)
