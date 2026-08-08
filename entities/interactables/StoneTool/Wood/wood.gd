extends Area2D

# --- KONFIGURASI INSPECTOR ---
@export_group("Story Settings")
# 🔒 Stage minimal yang harus dicapai agar kayu bisa diambil
@export var required_stage: GameState.StoryStage = GameState.StoryStage.BACK_TO_LAB 

# 🔥 TAMBAHAN: Variabel untuk memajukan progres cerita setelah kayu diambil
@export var advance_story_to: GameState.StoryStage = GameState.StoryStage.POST_SHOWER 

@export_group("Audio Settings")
# 🔥 TAMBAHAN: Efek suara saat mengambil kayu
@export var pickup_sound: AudioStream = null  # Isi di Inspector dengan file audio
@export var pickup_volume_db: float = 0.0  # Volume efek suara

# --- REFERENSI NODE INTERNAL ---
@onready var interact_label: Node = $Label if has_node("Label") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

# --- VARIABEL RUNTIME ---
var player_ref: Node2D = null
var is_collected: bool = false
var audio_player: AudioStreamPlayer2D = null

func _ready() -> void:
	# Cek apakah kayu sudah diambil sebelumnya
	if Global.has_wood == true:
		# 🔥 Tunda 1 frame agar Node lain (seperti LevelManager) selesai _ready()
		await get_tree().process_frame
		
		# 🔥 Majukan progres cerita jika kayu sudah pernah diambil tapi stage masih tertinggal
		if GameState.current_stage < advance_story_to:
			GameState.current_stage = advance_story_to
			print("Progres cerita diperbarui ke: ", GameState.current_stage)
			
		if collision_shape:
			collision_shape.disabled = true
		queue_free()
		return
	
	# Setup audio player
	_setup_audio()
	
	# Hubungkan sinyal area untuk mendeteksi player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	show_interact_prompt(false)

# --- FUNGSI SETUP AUDIO ---
func _setup_audio() -> void:
	# Cek apakah ada audio yang diisi di Inspector
	if pickup_sound == null:
		print("INFO: Tidak ada pickup sound yang di-set untuk Wood.")
		return
	
	# Buat AudioStreamPlayer2D
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.stream = pickup_sound
	audio_player.volume_db = pickup_volume_db
	audio_player.bus = "SFX"  # Gunakan bus SFX jika ada, atau default

# --- FUNGSI PLAY SOUND ---
func _play_pickup_sound() -> void:
	if audio_player and pickup_sound != null:
		audio_player.play()
		print("Wood pickup sound played!")

# --- PENANGANAN AREA / PLAYER DETEKSI ---
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		# 🔒 JIKA BELUM MENCAPAI STAGE CERITA, ABAIKAN DETEKSI (Prompt tidak muncul)
		if GameState.current_stage < required_stage:
			print("Kayu dikunci. Butuh stage: ", required_stage)
			return
			
		player_ref = body
		if "nearby_interactable" in body:
			body.nearby_interactable = self
		show_interact_prompt(true)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_ref = null
		if "nearby_interactable" in body and body.nearby_interactable == self:
			body.nearby_interactable = null
		show_interact_prompt(false)

func show_interact_prompt(show: bool) -> void:
	if interact_label:
		interact_label.visible = show

# --- LOGIKA UTAMA INTERAKSI ---
func interact() -> void:
	# 🔒 Filter keamanan ganda jika stage belum mencukupi saat ditekan
	if GameState.current_stage < required_stage:
		print("Interaksi ditolak: Progres cerita belum mencapai ", required_stage)
		return

	# Cek apakah sudah diambil
	if is_collected:
		return
	
	# Cek apakah player masih di dekat
	if player_ref == null:
		return
	
	# 🔥 MAIN KAN EFEK SUARA SEBELUM OBJEK DIHANCURKAN
	_play_pickup_sound()
	
	# Ambil kayu
	is_collected = true
	Global.has_wood = true
	print("Kayu berhasil diambil!")
	
	# 🔥 MAJUKAN PROGRES CERITA
	if GameState.current_stage < advance_story_to:
		GameState.current_stage = advance_story_to
		print("Progres cerita diperbarui ke: ", GameState.current_stage)
	
	# Sembunyikan prompt
	show_interact_prompt(false)
	
	# Bersihkan referensi dari player sebelum objek dihancurkan agar tidak error
	if player_ref and player_ref.get("nearby_interactable") == self:
		player_ref.nearby_interactable = null
	
	# 🔥 TUNDA PENGHANCURAN AGAR SUARA SEMPAT TERDENGAR
	# Jika suara pendek (< 0.5 detik), tunggu sebentar
	var wait_time: float = 0.3  # Default 0.3 detik
	if audio_player and pickup_sound != null:
		# Coba dapatkan durasi audio
		var duration = pickup_sound.get_length()
		if duration > 0 and duration < 1.0:
			wait_time = duration + 0.1  # Tambah sedikit agar suara selesai
		elif duration > 0:
			wait_time = min(duration, 0.5)  # Maksimal 0.5 detik
	
	# Hapus objek setelah suara diputar
	await get_tree().create_timer(wait_time).timeout
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	queue_free()

# --- CLEANUP ---
func _exit_tree() -> void:
	# Hentikan audio saat objek dihapus
	if audio_player:
		audio_player.stop()
