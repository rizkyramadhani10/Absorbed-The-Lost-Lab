extends Node2D

# 📈 DAFAR MULTIPLE TRIGGERS (Diisi via Inspector)
@export_group("Multiple Trigger Settings")
@export var triggers: Array[LabTriggerConfig] = []

@onready var player = $Player
@onready var blink_effect = $BlinkBlurEffect if has_node("BlinkBlurEffect") else null
@onready var anim_player = $BlinkBlurEffect/AnimationPlayer if has_node("BlinkBlurEffect/AnimationPlayer") else null

var is_dialog_playing: bool = false

func _ready() -> void:
	print("Spawn point yang diterima dari Global di Third Lab: ", Global.spawn_point)
	add_to_group("game")
	
	# 1. Atur posisi spawn player
	setup_third_lab_spawns()
	
	# 2. Setup semua trigger area berdasarkan stage & status completion
	setup_all_triggers()
	
	# 🎬 3. CEK APAKAH PERTAMA KALI BERMAIN (Wake Up Cutscene)
	if TransitionScreen.is_first_time_play:
		if player:
			player.set_physics_process(false)
			player.set_process_unhandled_input(false)
		
		if anim_player:
			anim_player.play("wake_up")
		TransitionScreen.is_first_time_play = false
	else:
		if blink_effect:
			blink_effect.queue_free()

# Fungsi untuk mengatur posisi spawn Player
func setup_third_lab_spawns() -> void:
	if Global.spawn_point == "SpawnFromSecondLab":
		if has_node("SpawnFromSecondLab"):
			player.global_position = $SpawnFromSecondLab.global_position
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromSecondLab!")
		else:
			print("ERROR di Third Lab: Marker 'SpawnFromSecondLab' tidak ditemukan!")
			
	elif Global.spawn_point == "SpawnFromStorage":
		if has_node("SpawnFromStorage"):
			player.global_position = $SpawnFromStorage.global_position
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromStorage!")
		else:
			print("ERROR: Marker 'SpawnFromStorage' tidak ditemukan!")
			
	elif Global.spawn_point == "SpawnFromMeadow":
		if has_node("SpawnFromMeadow"):
			player.global_position = $SpawnFromMeadow.global_position
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromMeadow!")
		else:
			print("ERROR di Meadow: Marker 'SpawnFromMeadow' tidak ditemukan!")

# --- SETUP SEMUA TRIGGER AREA ---

func setup_all_triggers() -> void:
	for config in triggers:
		if config == null or config.trigger_node == null:
			continue
			
		var trigger_area = get_node_or_null(config.trigger_node) as Area2D
		if trigger_area == null:
			print("ERROR: Node trigger di path '", config.trigger_node, "' tidak ditemukan!")
			continue
			
		# 1. Jika trigger sudah pernah diselesaikan sebelumnya, langsung hapus dari scene
		if config.completion_flag != "" and Global.get(config.completion_flag) == true:
			trigger_area.queue_free()
			print("Trigger '", config.completion_flag, "' sudah pernah dilewati. Dihapus.")
			continue
			
		# 2. Atur kemunculan & aktifkan monitoring HANYA jika stage saat ini cocok
		if GameState.current_stage == config.target_stage:
			trigger_area.monitoring = true
			trigger_area.visible = true
		else:
			trigger_area.monitoring = false
			trigger_area.visible = false
			
		# 3. Hubungkan sinyal body_entered
		if not trigger_area.body_entered.is_connected(_on_trigger_body_entered.bind(config, trigger_area)):
			trigger_area.body_entered.connect(_on_trigger_body_entered.bind(config, trigger_area))

# --- HANDLER LOGIKA UNTUK SETIAP TRIGGER AREA ---

func _on_trigger_body_entered(body: Node2D, config: LabTriggerConfig, trigger_area: Area2D) -> void:
	if (body == player or body.is_in_group("player")) and not is_dialog_playing:
		if GameState.current_stage == config.target_stage:
			
			# Matikan pemantauan trigger ini agar tidak memicu ganda
			trigger_area.set_deferred("monitoring", false)
			is_dialog_playing = true
			
			# Simpan status completion flag ke Global
			if config.completion_flag != "":
				Global.set(config.completion_flag, true)
			
			# Beri jeda 1 frame agar posisi kamera/UI stabil
			await get_tree().process_frame
			
			# Kunci pergerakan player
			body.set_physics_process(false)
			if body.has_method("set_process_unhandled_input"):
				body.set_process_unhandled_input(false)
				
			# Jalankan dialog jika path dialog diisi di Inspector
			if config.dialog_path != "":
				var dp = body.find_child("DialogPlayer", true, false)
				if dp != null:
					var dialogue_resource = load(config.dialog_path)
					dp._dialog_data = dialogue_resource
					dp.start()
					await dp.dialog_ended
				else:
					print("ERROR: Node 'DialogPlayer' tidak ditemukan pada " + body.name)
			
			# Majukan progres cerita secara aman
			if GameState.current_stage < config.advance_story_to:
				GameState.current_stage = config.advance_story_to
				print("Progres cerita diperbarui ke: ", GameState.current_stage)
			
			# Hapus area trigger dari scene agar tidak memblokir pemain lagi
			trigger_area.queue_free()
			
			# Kembalikan kontrol player
			body.set_physics_process(true)
			if body.has_method("set_process_unhandled_input"):
				body.set_process_unhandled_input(true)
				
			is_dialog_playing = false

# --- SIGNAL DARI ANIMATIONPLAYER (WAKE UP CUTSCENE) ---

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "wake_up":
		print("Animasi wake_up selesai. Memulai dialog awal...")
		
		if blink_effect:
			blink_effect.queue_free()
			
		await get_tree().process_frame
		
		var dialogue_resource = load("res://dialogues/Dialogues/AllDialogues/dialog_01_awake.json.tres")
		
		if player:
			var dp = player.find_child("DialogPlayer", true, false)
			if dp:
				dp._dialog_data = dialogue_resource
				dp.start()
				await dp.dialog_ended
			
			player.set_physics_process(true)
			player.set_process_unhandled_input(true)
			
		print("Player sadar sepenuhnya dan siap bergerak!")
