extends Node2D

# 📈 PENGATURAN PROGRESS CERITA & TRIGGER
@export_group("Trigger Settings")
# Stage yang akan dituju saat trigger disentuh
@export var advance_story_to: GameState.StoryStage = GameState.StoryStage.ENTERED_LAB1
# (Opsional) Path dialog jika trigger ini juga memunculkan percakapan
@export_file("*.tres") var trigger_dialog_path: String = ""
# 🚩 Nama unik di Global untuk menandai bahwa trigger ini sudah pernah diselesaikan (Contoh: "storage_dialog_done")
@export var completion_flag: String = ""

# 🔊 PENGATURAN AMBIENT SOUND
@export_group("Audio Settings")
@export var ambient_sound: AudioStream = null # Masukkan file audio ambient di Inspector
@export var ambient_volume_db: float = -10.0  # Atur volume ambient

@onready var player = $Player
@onready var dialogue_trigger = $DialogueTrigger if has_node("DialogueTrigger") else null

var is_dialog_playing: bool = false
var ambient_player: AudioStreamPlayer = null

func _ready() -> void:
	print("Spawn point yang diterima dari Global di Third Lab: ", Global.spawn_point)
	
	add_to_group("game")
	
	# 🔥 Setup & Putar Ambient Sound
	setup_ambient_sound()
	
	# 🔥 1. CEK APAKAH TRIGGER INI PERNAH DISELESAIKAN SEBELUMNYA
	if completion_flag != "" and Global.get(completion_flag) == true:
		if dialogue_trigger:
			# Hapus atau matikan trigger secara permanen agar tidak memblokir player
			dialogue_trigger.queue_free()
			print("Trigger '", completion_flag, "' sudah pernah dilewati. Dihapus dari scene.")
	
	# 🔥 Pindahkan posisi player secara instan saat scene dimuat (Tanpa delay)
	setup_meawdow_spawns()
		
	# Kosongkan teks setelah intro selesai
	SubtitleUi.show_typewriter_text("")
	
	# 🔥 Setup koneksi signal untuk DialogueTrigger
	setup_dialogue_trigger()

# 🔊 FUNGSI MEMUTAR AMBIENT SOUND
func setup_ambient_sound() -> void:
	if ambient_sound != null:
		ambient_player = AudioStreamPlayer.new()
		add_child(ambient_player)
		ambient_player.stream = ambient_sound
		ambient_player.volume_db = ambient_volume_db
		ambient_player.play()
		print("Ambient sound berhasil diputar!")
	else:
		print("INFO: Tidak ada Ambient Sound yang di-set di Inspector.")

# Fungsi untuk mengatur posisi spawn Player secara aman dan instan di Third Lab
func setup_meawdow_spawns() -> void:
	if Global.spawn_point == "SpawnFromThirdLab":
		if has_node("SpawnFromThirdLab"):
			# Menggunakan set_deferred agar posisi diubah tepat di frame pertama tanpa delay visual
			player.set_deferred("global_position", $SpawnFromThirdLab.global_position)
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromThirdLab!")
		else:
			print("ERROR di Meawdow: Marker 'SpawnFromThirdLab' tidak ditemukan di Scene Tree!")
	elif Global.spawn_point == "SpawnFromForest":
		if has_node("SpawnFromForest"):
			# Menggunakan set_deferred agar posisi diubah tepat di frame pertama tanpa delay visual
			player.set_deferred("global_position", $SpawnFromForest.global_position)
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromForest!")
		else:
			print("ERROR di Meawdow: Marker 'SpawnFromForest' tidak ditemukan di Scene Tree!")

# 🔥 Fungsi baru untuk menghubungkan signal trigger
func setup_dialogue_trigger() -> void:
	if dialogue_trigger:
		if not dialogue_trigger.body_entered.is_connected(_on_dialogue_trigger_body_entered):
			dialogue_trigger.body_entered.connect(_on_dialogue_trigger_body_entered)
	else:
		print("INFO: Node 'DialogueTrigger' tidak ditemukan di scene ini.")

# 🔥 Logika saat pemain menyentuh Area2D DialogueTrigger
func _on_dialogue_trigger_body_entered(body: Node2D) -> void:
	if (body == player or body.is_in_group("player")) and not is_dialog_playing:
		
		# Simpan status ke Global agar tidak muncul lagi saat kembali ke scene ini
		if completion_flag != "":
			Global.set(completion_flag, true)
		
		# Matikan pemantauan trigger agar tidak ter-trigger berkali-kali saat pemain mondar-mandir
		dialogue_trigger.set_deferred("monitoring", false)
		
		# 1. MAJUKAN GAME STATE SECARA AMAN
		if GameState.current_stage < advance_story_to:
			GameState.current_stage = advance_story_to
			print("Progres cerita diperbarui ke: ", GameState.current_stage)
			
		# 2. JALANKAN DIALOG (Jika path dialog di Inspector diisi)
		if trigger_dialog_path != "":
			_play_trigger_dialog(body)

# 🔥 Fungsi untuk memutar dialog dan mengunci pergerakan pemain
func _play_trigger_dialog(player_node: Node2D) -> void:
	is_dialog_playing = true
	
	# Beri jeda 1 frame agar posisi kamera & UI mereset
	await get_tree().process_frame
	
	# Lock dialog + kunci/buka kontrol player ditangani PlayerGate
	await PlayerGate.play_locked_dialog(player_node, trigger_dialog_path)
		
	is_dialog_playing = false
