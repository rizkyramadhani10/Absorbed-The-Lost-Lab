# Skrip: ui_tutorial.gd
extends ColorRect

signal tutorial_selesai

@onready var tablet_frame = $TabletFrame
@onready var tombol_mulai = $TabletFrame/TombolMulai

var slide_tween: Tween

func _ready() -> void:
	# 1. Pastikan background hitam transparan langsung memenuhi layar secara instan
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 2. Jalankan animasi tablet muncul dari bawah
	animasi_tablet_muncul()
	
	# 3. Hubungkan tombol mulai
	if tombol_mulai:
		tombol_mulai.pressed.connect(_on_tombol_mulai_pressed)

func animasi_tablet_muncul() -> void:
	if not tablet_frame:
		return
		
	# Dapatkan tinggi layar game saat ini
	var screen_height = get_viewport().get_visible_rect().size.y
	
	# Ambil posisi tengah asli si tablet yang sudah kamu atur di editor
	var posisi_tengah_asli = tablet_frame.position
	
	# Set posisi awal tablet di bawah luar layar sebelum animasi dimulai
	tablet_frame.position.y = screen_height + 100 
	
	# Matikan tween lama jika masih berjalan
	if slide_tween and slide_tween.is_running():
		slide_tween.kill()
		
	# Mulai animasi slide up dengan jeda/delay di awal
	slide_tween = create_tween()
	slide_tween.tween_property(tablet_frame, "position:y", posisi_tengah_asli.y, 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)\
		.set_delay(0.5) # <--- JEDA WAKTU (Silakan ganti 0.5 detik ini sesuai seleramu)

func _on_tombol_mulai_pressed() -> void:
	# Animasi menutup (opsional): Jika ingin tabletnya turun dulu sebelum hilang
	if slide_tween and slide_tween.is_running():
		slide_tween.kill()
		
	var screen_height = get_viewport().get_visible_rect().size.y
	
	slide_tween = create_tween()
	slide_tween.tween_property(tablet_frame, "position:y", screen_height + 100, 0.3)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
		
	# Tunggu animasi turun selesai, baru hilangkan scene dan pemicu game mulai
	await slide_tween.finished
	tutorial_selesai.emit()
	queue_free()
