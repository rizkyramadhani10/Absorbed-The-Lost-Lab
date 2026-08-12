extends Node2D

# --- REFERENSI NODE ---
@onready var player = $Player

# --- AUDIO SETTINGS ---
@export var background_music: AudioStream = null  # Isi di Inspector dengan file audio
@export var music_volume_db: float = -20.0  # Volume default (lebih pelan)
@export var fade_in_duration: float = 1.5  # Durasi fade in saat mulai

# --- VARIABEL RUNTIME ---
var audio_player: AudioStreamPlayer2D = null
var is_music_playing: bool = false

func _ready() -> void:
	print("Spawn point yang diterima dari Global di Third Lab: ", Global.spawn_point)
	
	add_to_group("game")
	
	# 🔥 Pindahkan posisi player secara instan saat scene dimuat (Tanpa delay)
	setup_meawdow_spawns()
		
	# Kosongkan teks setelah intro selesai
	SubtitleUi.show_typewriter_text("")
	
	# Setup audio background
	_setup_background_music()

# --- FUNGSI SETUP AUDIO ---
func _setup_background_music() -> void:
	# Cek apakah ada audio yang diisi di Inspector
	if background_music == null:
		print("INFO: Tidak ada background music yang di-set untuk Forest.")
		return
	
	# Buat AudioStreamPlayer2D jika belum ada
	if audio_player == null:
		audio_player = AudioStreamPlayer2D.new()
		add_child(audio_player)
		
		# Set stream
		audio_player.stream = background_music
		audio_player.volume_db = music_volume_db
		
		# Set untuk loop
		audio_player.finished.connect(_on_music_finished)
		
		# Play dengan fade in
		_play_music_with_fade_in()

func _play_music_with_fade_in() -> void:
	if audio_player == null or background_music == null:
		return
	
	if is_music_playing:
		return
	
	# Set volume awal ke 0 (senyap) lalu naikkan perlahan
	audio_player.volume_db = -80.0  # Sangat pelan
	audio_player.play()
	is_music_playing = true
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(audio_player, "volume_db", music_volume_db, fade_in_duration)

func _on_music_finished() -> void:
	# Jika musik selesai dan masih di scene ini, putar ulang
	if is_music_playing and is_inside_tree():
		# Reset volume ke awal dan play ulang
		audio_player.volume_db = music_volume_db
		audio_player.play()
		print("Forest background music looped!")

# --- FUNGSI UNTUK MENGONTROL MUSIK ---
func play_music() -> void:
	if audio_player and not is_music_playing:
		_play_music_with_fade_in()

func stop_music(fade_out_duration: float = 1.0) -> void:
	if audio_player and is_music_playing:
		is_music_playing = false
		var tween = create_tween()
		tween.tween_property(audio_player, "volume_db", -80.0, fade_out_duration)
		await tween.finished
		audio_player.stop()
		audio_player.volume_db = music_volume_db

func set_music_volume(volume: float) -> void:
	if audio_player:
		audio_player.volume_db = volume
		music_volume_db = volume

func get_music_volume() -> float:
	return music_volume_db

# Fungsi untuk mengatur posisi spawn Player secara aman dan instan di Third Lab
func setup_meawdow_spawns() -> void:
	if Global.spawn_point == "SpawnFromMeadow":
		if has_node("SpawnFromMeadow"):
			# Menggunakan set_deferred agar posisi diubah tepat di frame pertama tanpa delay visual
			player.set_deferred("global_position", $SpawnFromMeadow.global_position)
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromMeadow!")
		else:
			print("ERROR di Meawdow: Marker 'SpawnFromMeadow' tidak ditemukan di Scene Tree!")
	elif Global.spawn_point == "SpawnFromVolcanic":
		if has_node("SpawnFromVolcanic"):
			# Menggunakan set_deferred agar posisi diubah tepat di frame pertama tanpa delay visual
			player.set_deferred("global_position", $SpawnFromVolcanic.global_position)
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromVolcanic!")
		else:
			print("ERROR di Meawdow: Marker 'SpawnFromVolcanic' tidak ditemukan di Scene Tree!")

# --- CLEANUP ---
func _exit_tree() -> void:
	# Bersihkan audio saat scene ditutup
	if audio_player:
		audio_player.stop()
		audio_player.queue_free()
