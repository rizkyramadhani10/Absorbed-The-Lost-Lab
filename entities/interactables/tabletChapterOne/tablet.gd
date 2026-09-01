extends CanvasLayer

@export var tablet_text: String = ""
@export var is_quiz_tablet: bool = false
# 🔥 Pastikan nama ini sama dengan quiz_completion_flag di Inspector alat/komputer
@export var quiz_flag_name: String = "is_quiz_completed"

# === NODE REFERENCES VIA @export ===
@export var background_sprite: Sprite2D
@export var text_label: Label
@export var close_button: Button
@export var quiz_manager: Control

# === TEXTURE ASSETS ===
@export var default_tablet_bg: Texture2D
@export var certificate_tablet_bg: Texture2D

var game_world: Node = null
var player: Node = null
var slide_tween: Tween

func _ready():
	visible = false
	if quiz_manager:
		quiz_manager.visible = false
		if not quiz_manager.quiz_finished.is_connected(_on_quiz_finished):
			quiz_manager.quiz_finished.connect(_on_quiz_finished)
			
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func open(world, player_node):
	game_world = world
	player = player_node
	
	if background_sprite and default_tablet_bg:
		background_sprite.texture = default_tablet_bg
	
	if player:
		player.set_process(false)
		player.set_physics_process(false)
	
	var screen_height = get_viewport().get_visible_rect().size.y
	offset.y = screen_height
	visible = true
	
	if slide_tween and slide_tween.is_running():
		slide_tween.kill() 
		
	slide_tween = create_tween()
	slide_tween.tween_property(self, "offset:y", 0.0, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# 📑 LOGIKA PENGECEKAN KUIS
	if is_quiz_tablet and quiz_manager:
		# Cek apakah player benar-benar sudah lulus
		if Global.get(quiz_flag_name) == true:
			if quiz_manager: quiz_manager.visible = false
			if text_label:
				text_label.visible = true
				SubtitleUi.show_typewriter_text("Kamu sudah menyelesaikan kuis ini dan mendapatkan sertifikat!")
			if background_sprite and certificate_tablet_bg:
				background_sprite.texture = certificate_tablet_bg
		else:
			if text_label: text_label.visible = false
			# Pastikan QuizManager dibuat terlihat kembali jika pemain mengulang
			quiz_manager.visible = true 
			quiz_manager.start_quiz() 
	else:
		if text_label:
			text_label.visible = true
			if quiz_manager: quiz_manager.visible = false
			if tablet_text != null and tablet_text != "":
				SubtitleUi.show_typewriter_text(tablet_text)
			else:
				SubtitleUi.show_typewriter_text("Tablet tidak berisi data.")

func close():
	var screen_height = get_viewport().get_visible_rect().size.y
	if slide_tween and slide_tween.is_running():
		slide_tween.kill()
		
	slide_tween = create_tween()
	slide_tween.tween_property(self, "offset:y", screen_height, 0.3)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
		
	await slide_tween.finished
	
	if game_world: game_world.visible = true
	if player and is_instance_valid(player):
		player.set_process(true)
		player.set_physics_process(true)
	
	visible = false
	game_world = null
	player = null

func _on_close_pressed():
	close()

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		close()

# === SWAP TEXTURE ONCE SIGNAL FIRES ===
func _on_quiz_finished(passed: bool):
	print("DEBUG KUIS: Sinyal diterima. Apakah lulus? ", passed)
	if passed:
		# Simpan status permanen kalau pemain LULUS kuis
		Global.set(quiz_flag_name, true)
		
		if background_sprite and certificate_tablet_bg:
			background_sprite.texture = certificate_tablet_bg
			
		var main_scene = get_tree().current_scene
		if main_scene:
			var portal = main_scene.find_child("TimeMachineSpiralPortal", true, false)
			if portal:
				portal.visible = true
				portal.process_mode = Node.PROCESS_MODE_INHERIT 
				print("SUKSES: Portal berhasil dibuka!")
			else:
				print("ERROR: TimeMachineSpiralPortal tidak ditemukan di dalam struktur Scene aktif!")
		else:
			print("ERROR: Scene utama tidak terdeteksi!")
