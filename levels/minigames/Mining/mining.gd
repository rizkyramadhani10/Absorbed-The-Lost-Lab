extends Node2D

# 🔥 EXPORT: Path ke scene utama (bisa diatur dari inspektor)
@export var main_game_scene: PackedScene = null

# Referensi node
@onready var batu = $Batu
@onready var kampak = $Kampak
@onready var progress_bar = $ProgressBar
@onready var tombol_mining = $TombolMining
@onready var label_notifikasi = $LabelNotifikasi  # Tambahkan label

# Variabel mining
var is_mining = false
var mining_progress = 0.0
const MINING_SPEED = 0.1  
const MAX_PROGRESS = 100.0
var kampak_rotation_direction = 2
var is_mining_complete = false  # Flag untuk cegah aksi ganda

func _ready():
	# Setup awal
	progress_bar.max_value = MAX_PROGRESS
	progress_bar.value = 0
	kampak.rotation = 0
	
	# 🔥 Sembunyikan label notifikasi di awal
	if label_notifikasi:
		label_notifikasi.visible = false
		label_notifikasi.text = "Sulfur berhasil didapatkan!"
	
	# Signal untuk tombol
	tombol_mining.button_down.connect(_on_mining_start)
	tombol_mining.button_up.connect(_on_mining_stop)
	
	# Validasi
	if main_game_scene == null:
		print("WARNING: Main game scene belum di-set di inspektor!")

func _process(delta):
	if is_mining and not is_mining_complete:
		# Tambah progress
		mining_progress += MINING_SPEED * delta * 100
		progress_bar.value = mining_progress
		
		# Animasi kampak (rotasi naik-turun)
		_animate_pickaxe(delta)
		
		# Cek apakah mining selesai
		if mining_progress >= MAX_PROGRESS:
			_mining_complete()

func _animate_pickaxe(delta):
	# Gerakan rotasi kampak seperti sedang menambang
	var target_rotation = deg_to_rad(90) * kampak_rotation_direction
	
	# Interpolasi rotasi
	kampak.rotation = lerp(kampak.rotation, target_rotation, delta * 5)
	
	# Balik arah jika sudah mencapai batas
	if abs(kampak.rotation) >= deg_to_rad(88):
		kampak_rotation_direction *= -1

func _on_mining_start():
	if batu.visible and not is_mining_complete:  # Cek apakah batu masih ada dan belum selesai
		is_mining = true
		print("Mining dimulai!")
	else:
		print("Batu sudah tidak ada atau mining sudah selesai!")

func _on_mining_stop():
	if not is_mining_complete:  # Hanya reset jika belum selesai
		is_mining = false
		print("Mining dihentikan!")
		# Reset posisi kampak
		kampak.rotation = 0

func _mining_complete():
	# Mining selesai
	is_mining = false
	is_mining_complete = true  # Tandai selesai
	batu.visible = false  # Batu hilang
	kampak.rotation = 0
	mining_progress = 0
	progress_bar.value = 0
	print("Batu berhasil ditambang!")
	
	# 🔥 Tampilkan notifikasi
	_show_notification()

func _show_notification():
	if label_notifikasi:
		# Tampilkan label
		label_notifikasi.visible = true
		print("Notifikasi: Sulfur berhasil didapatkan!")
		
		# 🔥 Tunggu 2 detik lalu kembali ke scene utama
		await get_tree().create_timer(2.0).timeout
		_go_back_to_game()
	else:
		print("ERROR: Label notifikasi tidak ditemukan!")
		# Fallback: langsung kembali
		_go_back_to_game()

func _go_back_to_game():
	print("Kembali ke game utama...")
	
	# 🔥 Gunakan PackedScene yang sudah di-export
	if main_game_scene != null:
		get_tree().change_scene_to_packed(main_game_scene)
	else:
		print("ERROR: Main game scene tidak ditemukan! Silakan set di inspektor.")
		# Fallback: coba cari scene utama dengan path default
		var fallback_path = "res://Game.tscn"
		if FileAccess.file_exists(fallback_path):
			get_tree().change_scene_to_file(fallback_path)
		else:
			print("ERROR: Tidak bisa kembali ke scene utama!")

# Fungsi untuk reset (jika diperlukan)
func reset_mining():
	batu.visible = true
	is_mining_complete = false
	mining_progress = 0
	progress_bar.value = 0
	kampak.rotation = 0
	is_mining = false
	if label_notifikasi:
		label_notifikasi.visible = false
