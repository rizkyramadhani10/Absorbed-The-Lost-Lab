extends Node2D

@onready var area_interaksi = $Area2D
@onready var progress_bar = $"../../ProgressBar"
@onready var video_overlay = $"../../VideoStreamPlayer"
@onready var sfx_air = $"../../SFXShower"

var tutorial_scene = preload("res://levels/minigames/safetyShower/Tutorial/UI_Tutorial.tscn")

var is_pulling = false
var posisi_awal_y = 0.0
var last_mouse_y = 0.0 

var tween_overlay = null 
var tween_sfx = null 
var volume_asli = 0.0 
var is_shower_active = false 

@export var batas_tarik_bawah = 90.0 
@export var kecepatan_isi = 150.0 
@export var batas_trigger_air = 70.0 

# ==========================================
# 🧪 [FISIKA] Variabel buat pegas
# ==========================================
var kecepatan_y = 0.0
@export var kekuatan_per = 350.0 
@export var kelenturan = 12.0 

# ==========================================
# 🏁 [TAMBAHAN] Variabel buat Menang & Pindah Scene
# ==========================================
var is_finished = false

func _ready():
	munculkan_tutorial_langsung()
	
	posisi_awal_y = global_position.y
	if progress_bar: 
		progress_bar.value = 0
		progress_bar.step = 0.01
	
	if video_overlay:
		video_overlay.visible = true
		video_overlay.modulate.a = 0.0 
		
	if sfx_air:
		volume_asli = sfx_air.volume_db
	
	if area_interaksi:
		area_interaksi.input_event.connect(_on_input_event)
	
func munculkan_tutorial_langsung() -> void:
	var tutorial_instance = tutorial_scene.instantiate()
	# Masukkan langsung ke root scene tree agar terbebas dari posisi Node2D ini
	get_tree().root.add_child.call_deferred(tutorial_instance)
	
func _process(delta):
	# 1. LOGIKA PERGERAKAN TUAS
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

	# 2. LOGIKA TRIGGER AIR & BAR
	if global_position.y > posisi_awal_y + batas_trigger_air:
		if not is_shower_active:
			is_shower_active = true 
			if video_overlay and not video_overlay.is_playing(): video_overlay.play()
			if sfx_air: 
				if tween_sfx: tween_sfx.kill() 
				sfx_air.volume_db = volume_asli 
				if not sfx_air.playing: sfx_air.play()
			
			if tween_overlay: tween_overlay.kill()
			tween_overlay = create_tween()
			tween_overlay.tween_property(video_overlay, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		if progress_bar:
			progress_bar.value += kecepatan_isi * delta
			if progress_bar.value >= progress_bar.max_value and not is_finished:
				game_finished()
	else:
		if is_shower_active:
			is_shower_active = false 
			if tween_overlay: tween_overlay.kill()
			tween_overlay = create_tween()
			tween_overlay.tween_property(video_overlay, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween_overlay.tween_callback(video_overlay.stop)
			
			if sfx_air:
				if tween_sfx: tween_sfx.kill()
				tween_sfx = create_tween()
				tween_sfx.tween_property(sfx_air, "volume_db", -60.0, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
				tween_sfx.tween_callback(sfx_air.stop)

func _on_input_event(viewport, event, shape_idx):
	if is_finished: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pulling = true
			last_mouse_y = get_global_mouse_position().y

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_pulling = false

# ==========================================
# 3. LOGIKA TAMAT & LOADING SCREEN
# ==========================================
func game_finished():
	print("🚿 MINIGAME SAFETY SHOWER SELESAI!")
	is_finished = true
	is_pulling = false 
	Global.is_shower_completed = true 
	
	# Tunggu sebentar biar efek visual selesai dulu
	await get_tree().create_timer(1.0).timeout
	pindah_ke_scene_tujuan()

func pindah_ke_scene_tujuan():
	var tujuan_final = ""
	if Global.scene_asal_path != "":
		tujuan_final = Global.scene_asal_path
	else:
		tujuan_final = "res://levels/thirdLab(TimeMachine)/game.tscn"
		
	print("🔄 Memulangkan player ke: ", tujuan_final)
	
	# PAKE LOADING SCREEN TRANSITION (DIBALIKIN LAGI SESUAI REQUEST)
	if has_node("/root/TransitionScreen"):
		TransitionScreen.transition_to_scene(tujuan_final)
	else:
		# Fallback jika TransitionScreen tidak ditemukan
		get_tree().change_scene_to_file(tujuan_final)
