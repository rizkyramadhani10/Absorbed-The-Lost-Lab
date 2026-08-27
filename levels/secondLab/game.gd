extends Node2D

# ==========================================
# 🔊 PENGATURAN AMBIENT SOUND (TAMBAHAN BARU)
# ==========================================
@export_group("Audio Settings")
@export var ambient_sound: AudioStream = null # Masukkan file audio ambient di Inspector
@export var ambient_volume_db: float = -5.0  # Atur volume ambient

# ==========================================
# 📈 PENGATURAN PROGRESS CERITA & TRIGGER
# ==========================================
# 📄 Path file resource dialog .tres untuk filler dialog di SecondLab
@export_file("*.tres") var filler_dialog_path: String = ""

# 🔒 Syarat stage cerita (sesuaikan nama Stagenya jika berbeda di enum GameState kamu)
@export var target_stage: GameState.StoryStage = GameState.StoryStage.CHECKED_MONITOR

@onready var player = $Player
@onready var trig_middle_lab = $TrigMiddleLab

var is_dialog_playing: bool = false
var ambient_player: AudioStreamPlayer = null # (TAMBAHAN BARU)

func _ready() -> void:
	print("Spawn point yang diterima dari Global: ", Global.spawn_point)
	add_to_group("game")
	
	# 🔥 Setup & Putar Ambient Sound (TAMBAHAN BARU)
	setup_ambient_sound()
	
	# 1. Atur posisi spawn player
	setup_second_lab_spawns()
	
	# 2. Setup trigger di tengah lab
	setup_middle_lab_trigger()

# Fungsi untuk mengatur posisi spawn Player secara aman dan instan
func setup_second_lab_spawns() -> void:
	# Simpan ke variabel lokal dulu agar terbaca di blok if
	var current_spawn = Global.spawn_point
	
	if current_spawn == "SpawnFromWorkspace":
		if has_node("SpawnFromWorkspace"):
			# 🔥 PERBAIKAN: Gunakan set_deferred agar tidak bentrok dengan collision StoryBarrier
			player.set_deferred("global_position", $SpawnFromWorkspace.global_position)
			print("Second Lab: Player berhasil dipindahkan ke SpawnFromWorkspace!")
		else:
			print("ERROR di Second Lab: Marker 'SpawnFromWorkspace' tidak ditemukan di Scene Tree!")
			
	elif current_spawn == "SpawnFromThirdLab":
		if has_node("SpawnFromThirdLab"):
			# 🔥 PERBAIKAN: Gunakan set_deferred agar tidak bentrok dengan collision StoryBarrier
			player.set_deferred("global_position", $SpawnFromThirdLab.global_position)
			print("Second Lab: Player berhasil dipindahkan ke SpawnFromThirdLab!")
		else:
			print("ERROR di Second Lab: Marker 'SpawnFromThirdLab' tidak ditemukan di Scene Tree!")

	# 🔥 PERBAIKAN: Tunda reset 1 frame.
	# Ini mencegah StoryBarrier (yang mungkin berjalan setelah skrip ini) membaca string kosong.
	await get_tree().process_frame
	Global.spawn_point = ""

# Setup Signal & Monitoring Trigger
func setup_middle_lab_trigger() -> void:
	if has_node("TrigMiddleLab"):
		if not trig_middle_lab.body_entered.is_connected(_on_trig_middle_lab_body_entered):
			trig_middle_lab.body_entered.connect(_on_trig_middle_lab_body_entered)
		
		# Hanya aktifkan trigger jika stage cerita sesuai/memenuhi syarat
		if GameState.current_stage == target_stage:
			trig_middle_lab.monitoring = true
		else:
			trig_middle_lab.monitoring = false

func _on_trig_middle_lab_body_entered(body: Node2D) -> void:
	if (body == player or body.is_in_group("player")) and not is_dialog_playing:
		if GameState.current_stage == target_stage:
			
			# 🔍 CEK 1: Path dialog di Inspector
			if filler_dialog_path == "":
				print("ERROR di SecondLab: 'Filler Dialog Path' di Inspector masih KOSONG!")
				return
			
			# Matikan pemantauan trigger agar tidak berulang
			trig_middle_lab.set_deferred("monitoring", false)
			is_dialog_playing = true
			
			# 🔥 FIX LAYOUT UI TERPOTONG:
			# Beri jeda 1 frame agar posisi kamera & UI mereset dulu ke posisi Xeno
			await get_tree().process_frame
			
			# Lock dialog + kunci/buka kontrol player ditangani PlayerGate
			await PlayerGate.play_locked_dialog(body, filler_dialog_path)
				
			is_dialog_playing = false

# ==========================================
# 🔊 FUNGSI MEMUTAR AMBIENT SOUND (TAMBAHAN BARU)
# ==========================================
func setup_ambient_sound() -> void:
	if ambient_sound != null:
		ambient_player = AudioStreamPlayer.new()
		add_child(ambient_player)
		ambient_player.stream = ambient_sound
		ambient_player.volume_db = ambient_volume_db
		ambient_player.play()
		print("Ambient sound di Second Lab berhasil diputar!")
	else:
		print("INFO: Tidak ada Ambient Sound yang di-set di Inspector Second Lab.")
