extends Node2D

@onready var area_interaksi = $Area2D
@onready var progress_bar = $"../ProgressBar"
@onready var video_overlay = $"../VideoStreamPlayer" 
@onready var sfx_air = $"../SFXShower" 

var is_pulling = false
var posisi_awal_y = 0.0
var last_mouse_y = 0.0 

var tween_overlay = null 
var tween_sfx = null 
var volume_asli = 0.0 
var is_shower_active = false 

@export var batas_tarik_bawah = 90.0 
@export var kecepatan_isi = 50.0 
@export var batas_trigger_air = 70.0 

# ==========================================
# 🧪 [TAMBAHAN FISIKA] Variabel buat pegas
# ==========================================
var kecepatan_y = 0.0
@export var kekuatan_per = 350.0 
@export var kelenturan = 12.0 

func _ready():
	posisi_awal_y = global_position.y
	if progress_bar: progress_bar.value = 0
	
	if video_overlay:
		video_overlay.visible = true
		video_overlay.modulate.a = 0.0 
		
	if sfx_air:
		volume_asli = sfx_air.volume_db
	
	if area_interaksi:
		area_interaksi.input_event.connect(_on_input_event)

func _process(delta):
	# ==========================================
	# 1. LOGIKA PERGERAKAN TUAS (Mouse & Fisika)
	# ==========================================
	if is_pulling:
		var current_mouse_y = get_global_mouse_position().y
		var delta_y = current_mouse_y - last_mouse_y
		last_mouse_y = current_mouse_y
		
		kecepatan_y = 0.0
		global_position.y += delta_y
		global_position.y = clamp(global_position.y, posisi_awal_y, posisi_awal_y + batas_tarik_bawah)
	else:
		var jarak = global_position.y - posisi_awal_y
		var gaya_pegas = -kekuatan_per * jarak
		var gaya_redam = -kelenturan * kecepatan_y
		
		kecepatan_y += (gaya_pegas + gaya_redam) * delta
		global_position.y += kecepatan_y * delta
		
		if global_position.y > posisi_awal_y + batas_tarik_bawah:
			global_position.y = posisi_awal_y + batas_tarik_bawah
			kecepatan_y *= -0.5 

	# ==========================================
	# 2. LOGIKA TRIGGER AIR & BAR (Berdasarkan Posisi)
	# ==========================================
	if global_position.y > posisi_awal_y + batas_trigger_air:
		# --- FADE IN & ISI BAR ---
		if not is_shower_active:
			is_shower_active = true 
			
			if video_overlay and not video_overlay.is_playing(): 
				video_overlay.play()
			
			if sfx_air: 
				if tween_sfx: tween_sfx.kill() 
				sfx_air.volume_db = volume_asli 
				if not sfx_air.playing:
					sfx_air.play()
			
			# [DIUBAH] Transisi Sine In-Out biar munculnya elegan
			if tween_overlay: tween_overlay.kill()
			tween_overlay = create_tween()
			tween_overlay.tween_property(video_overlay, "modulate:a", 1.0, 0.5)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
		
		if progress_bar:
			progress_bar.value += kecepatan_isi * delta
			
	else:
		# --- FADE OUT & STOP BAR ---
		if is_shower_active:
			is_shower_active = false 
			
			# [DIUBAH] Transisi Sine Out biar ilangnya gak ngagetin
			if tween_overlay: tween_overlay.kill()
			tween_overlay = create_tween()
			tween_overlay.tween_property(video_overlay, "modulate:a", 0.0, 0.3)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_OUT)
			tween_overlay.tween_callback(video_overlay.stop)
			
			# [DIUBAH] Transisi Expo Out buat audio biar suaranya mereda kayak di dunia nyata
			if sfx_air:
				if tween_sfx: tween_sfx.kill()
				tween_sfx = create_tween()
				tween_sfx.tween_property(sfx_air, "volume_db", -60.0, 0.5)\
					.set_trans(Tween.TRANS_EXPO)\
					.set_ease(Tween.EASE_OUT)
				tween_sfx.tween_callback(sfx_air.stop)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pulling = true
			last_mouse_y = get_global_mouse_position().y

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_pulling = false
