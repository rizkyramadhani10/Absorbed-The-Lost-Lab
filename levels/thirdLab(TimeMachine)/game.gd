extends Node2D

# 📄 Path file resource dialog untuk Mesin Waktu (Diisi via Inspector)
@export_file("*.tres") var time_machine_dialog_path: String = ""

# 🔒 Syarat stage cerita agar dialog mesin waktu aktif
@export var target_stage: GameState.StoryStage = GameState.StoryStage.CHECKED_MONITOR

# 🔥 TAMBAHAN: Stage cerita tujuan setelah dialog mesin waktu selesai
@export var advance_story_to: GameState.StoryStage = GameState.StoryStage.CHECKED_TIME_MACHINE

@onready var player = $Player
@onready var blink_effect = $BlinkBlurEffect
@onready var anim_player = $BlinkBlurEffect/AnimationPlayer
@onready var trig_time_machine = $TrigTimeMachine

var is_dialog_playing: bool = false

func _ready() -> void:
	print("Spawn point yang diterima dari Global di Third Lab: ", Global.spawn_point)
	add_to_group("game")
	
	# 1. Atur posisi spawn player
	setup_third_lab_spawns()
	
	# 2. Setup trigger Mesin Waktu
	setup_time_machine_trigger()
	
	# 🎬 3. CEK APAKAH PERTAMA KALI BERMAIN (Wake Up Cutscene)
	if TransitionScreen.is_first_time_play:
		if player:
			player.set_physics_process(false)
			player.set_process_unhandled_input(false)
		
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

# --- SETUP & TRIGGER DARI TRIGTIMEMACHINE ---

func setup_time_machine_trigger() -> void:
	if has_node("TrigTimeMachine"):
		if not trig_time_machine.body_entered.is_connected(_on_trig_time_machine_body_entered):
			trig_time_machine.body_entered.connect(_on_trig_time_machine_body_entered)
		
		# Aktifkan monitoring hanya jika stage cerita memenuhi syarat
		if GameState.current_stage == target_stage:
			trig_time_machine.monitoring = true
		else:
			trig_time_machine.monitoring = false

func _on_trig_time_machine_body_entered(body: Node2D) -> void:
	if (body == player or body.is_in_group("player")) and not is_dialog_playing:
		if GameState.current_stage == target_stage:
			
			if time_machine_dialog_path == "":
				print("ERROR di ThirdLab: 'Time Machine Dialog Path' di Inspector masih KOSONG!")
				return
				
			var dp = body.find_child("DialogPlayer", true, false)
			if dp == null:
				print("ERROR di ThirdLab: Node 'DialogPlayer' tidak ditemukan pada " + body.name)
				return
			
			trig_time_machine.set_deferred("monitoring", false)
			is_dialog_playing = true
			
			# 🔥 FIX LAYOUT TERPOTONG: Beri jeda 1 frame sebelum dialog dijalankan
			await get_tree().process_frame
			
			# 1. Kunci kontrol player
			body.set_physics_process(false)
			if body.has_method("set_process_unhandled_input"):
				body.set_process_unhandled_input(false)
				
			# 2. Assign resource & jalankan dialog
			var dialogue_resource = load(time_machine_dialog_path)
			dp._dialog_data = dialogue_resource
			dp.start()
			
			# 3. Tunggu sampai dialog selesai
			await dp.dialog_ended
			
			# 🔥 MAJUKAN PROGRES CERITA
			if GameState.current_stage < advance_story_to:
				GameState.current_stage = advance_story_to
				print("Progres cerita diperbarui ke: ", GameState.current_stage)
			
			# 4. Kembalikan kontrol player
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
			
		# 🔥 FIX LAYOUT TERPOTONG: Beri jeda 1 frame agar posisi camera & UI pas
		await get_tree().process_frame
		
		var dialogue_resource = load("res://dialogues/Dialogues/AllDialogues/dialog_01_awake.json.tres")
		
		if player:
			var dp = player.find_child("DialogPlayer", true, false)
			if dp:
				dp._dialog_data = dialogue_resource
				dp.start()
				await dp.dialog_ended
			
			# Kembalikan kontrol player setelah dialog awake selesai
			player.set_physics_process(true)
			player.set_process_unhandled_input(true)
			
		print("Player sadar sepenuhnya dan siap bergerak!")
