extends Area2D

# --- KONFIGURASI INSPECTOR ---
@export_group("Audio Settings")
# 🔥 TAMBAHAN: Efek suara saat mining (akan di-loop)
@export var mining_sound: AudioStream = null  # Isi di Inspector dengan file audio
@export var mining_volume_db: float = 0.0  # Volume efek suara

# --- REFERENSI NODE ---
@onready var sulphur_sprite: Sprite2D = $sulphur
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Perbaiki: Gunakan path yang benar untuk Label (Node2D) dan ProgressBar
@onready var interact_label: Node2D = $Label  # Ini adalah Node2D, bukan Label Control
@onready var progress_bar: ProgressBar = $ProgressBar  # Pastikan ProgressBar sudah ditambahkan
# Cache child Label sekali di awal (hindari find_child rekursif setiap frame)
@onready var prompt_label: Label = interact_label.find_child("Label", true, false) as Label

# --- VARIABEL ---
var player_ref: Node2D = null
var is_holding_interact: bool = false
var hold_time: float = 0.0
var required_hold_time: float = 3.0  # 3 detik untuk menghancurkan
var is_destroyed: bool = false

# --- VARIABEL AUDIO ---
var audio_player: AudioStreamPlayer2D = null

# --- SIGNAL ---
signal sulfur_destroyed

func _ready():
	# Cek apakah sulfur sudah hancur sebelumnya
	if Global.is_sulfur_destroyed:
		_destroy_sulfur(true)
		return
	
	# Setup audio
	_setup_audio()
	
	# Hubungkan sinyal area
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Sembunyikan progress bar di awal
	_hide_progress()
	
	# Sembunyikan label interaksi di awal
	if interact_label:
		interact_label.visible = false
	
	# Nonaktifkan interaksi jika tidak ada alat
	_update_interactable_state()
	
	# _process hanya dibutuhkan saat hold-mining aktif
	set_process(false)

# --- FUNGSI SETUP AUDIO ---
func _setup_audio() -> void:
	# Cek apakah ada audio yang diisi di Inspector
	if mining_sound == null:
		print("INFO: Tidak ada mining sound yang di-set untuk Sulphur.")
		return
	
	# Buat AudioStreamPlayer2D
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.stream = mining_sound
	audio_player.volume_db = mining_volume_db
	audio_player.bus = "SFX"  # Gunakan bus SFX jika ada, atau default

# --- FUNGSI PLAY/STOP SOUND ---
func _play_mining_sound() -> void:
	if audio_player and mining_sound != null:
		# Set loop agar terus berulang selama proses mining
		# Guard agar koneksi tidak menumpuk bila dipanggil berulang kali
		if not audio_player.finished.is_connected(_on_mining_sound_finished):
			audio_player.finished.connect(_on_mining_sound_finished)
		audio_player.play()
		print("Mining sound started!")

func _stop_mining_sound() -> void:
	if audio_player and audio_player.playing:
		audio_player.stop()
		# Putuskan koneksi signal agar tidak loop lagi
		if audio_player.finished.is_connected(_on_mining_sound_finished):
			audio_player.finished.disconnect(_on_mining_sound_finished)
		print("Mining sound stopped!")

func _on_mining_sound_finished() -> void:
	# Jika masih dalam proses hold, loop sound
	if is_holding_interact and not is_destroyed:
		audio_player.play()
	else:
		# Jika tidak, stop
		_stop_mining_sound()

func _process(delta: float):
	# Proses hold interaksi
	if is_holding_interact and player_ref and not is_destroyed:
		# Cek apakah player masih memiliki alat
		if not Global.has_hammer:
			_cancel_hold()
			return
		
		hold_time += delta
		_update_progress(hold_time / required_hold_time)
		
		# Cek apakah sudah mencapai waktu yang dibutuhkan
		if hold_time >= required_hold_time:
			_destroy_sulfur()
	else:
		# Reset hold time jika tidak menahan
		if not is_destroyed:
			hold_time = 0.0
			if progress_bar:
				progress_bar.value = 0

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_ref = body
		body.nearby_interactable = self
		
		# Tampilkan prompt interaksi jika memiliki alat
		if Global.has_hammer and not is_destroyed:
			show_interact_prompt(true, "[Hold] Hancurkan Sulfur")

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_ref = null
		if body.nearby_interactable == self:
			body.nearby_interactable = null
		
		# Batalkan hold jika player keluar
		_cancel_hold()
		show_interact_prompt(false)

func show_interact_prompt(show: bool, text: String = ""):
	if interact_label:
		interact_label.visible = show
		if show and text and prompt_label:
			prompt_label.text = text

# --- FUNGSI INTERAKSI HOLD ---
func interact() -> void:
	# Dipanggil dari player saat tombol interaksi ditekan
	if is_destroyed:
		return
	
	# Cek apakah player memiliki alat
	if not Global.has_hammer:
		print("Tidak memiliki alat penghancur!")
		show_interact_prompt(true, "Butuh alat penghancur!")
		# Sembunyikan pesan setelah 2 detik
		await get_tree().create_timer(2.0).timeout
		if not is_destroyed:
			show_interact_prompt(false)
		return
	
	# Mulai hold
	if player_ref and not is_holding_interact:
		is_holding_interact = true
		hold_time = 0.0
		_show_progress()
		set_process(true)
		
		# 🔥 MAIN KAN SUARA MINING (LOOP)
		_play_mining_sound()
		
		print("Mulai menghancurkan sulfur...")

func interact_release() -> void:
	# Dipanggil dari player saat tombol interaksi dilepas
	_cancel_hold()

func _cancel_hold():
	is_holding_interact = false
	hold_time = 0.0
	set_process(false)
	_hide_progress()
	
	# 🔥 HENTIKAN SUARA MINING
	_stop_mining_sound()
	
	if prompt_label and not is_destroyed:
		prompt_label.text = ""

func _show_progress():
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0

func _hide_progress():
	if progress_bar:
		progress_bar.visible = false
		progress_bar.value = 0

func _update_progress(progress: float):
	if progress_bar:
		progress_bar.value = progress * 100
		# Update label dengan persentase (node sudah di-cache)
		if prompt_label:
			prompt_label.text = str(int(progress * 100)) + "%"

func _destroy_sulfur(instant: bool = false):
	if is_destroyed:
		return
	
	is_destroyed = true
	Global.is_sulfur_destroyed = true
	
	# 🔥 HENTIKAN SUARA MINING
	_stop_mining_sound()
	
	# Sembunyikan sprite dan collision
	if sulphur_sprite:
		sulphur_sprite.visible = false
	if collision_shape:
		collision_shape.disabled = true
	
	# Sembunyikan progress
	_cancel_hold()
	show_interact_prompt(false)
	
	# Emit signal
	sulfur_destroyed.emit()
	
	GameState.advance_to(GameState.StoryStage.OBTAINED_RESOURCE)
	
	print("Sulfur berhasil dihancurkan!")
	
	# Panggil efek atau dialog jika diperlukan
	if not instant:
		# Bisa tambahkan efek visual atau suara di sini
		pass

func _update_interactable_state():
	# Jika tidak memiliki alat, nonaktifkan interaksi
	if not Global.has_hammer and not is_destroyed:
		# Tampilkan pesan jika player di dekat
		if player_ref:
			show_interact_prompt(true, "Butuh alat penghancur!")
	else:
		if not is_destroyed and player_ref:
			show_interact_prompt(true, "[Hold] Hancurkan Sulfur")

# --- CLEANUP ---
func _exit_tree() -> void:
	# Hentikan audio saat objek dihapus
	if audio_player:
		audio_player.stop()
		if audio_player.finished.is_connected(_on_mining_sound_finished):
			audio_player.finished.disconnect(_on_mining_sound_finished)
