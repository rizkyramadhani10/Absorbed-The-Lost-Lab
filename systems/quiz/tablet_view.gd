extends CanvasLayer

@export var tablet_text: String = ""
@export var is_quiz_tablet: bool = false

# === NODE REFERENCES VIA @export ===
@export var background_sprite: Sprite2D   # Drag Panel/Sprite2D node ke sini
@export var text_label: Label             # Drag TxtDisplay Label ke sini
@export var close_button: Button          # Drag CloseBtn ke sini
@export var quiz_manager: Control         # Drag QuizManager ke sini

# === TEXTURE ASSETS ===
@export var default_tablet_bg: Texture2D       # Tablet Xeno (ATL).jpg
@export var certificate_tablet_bg: Texture2D   # Tablet Xeno (ATL + Certificate).jpg

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
	
	# Reset background ke default awal saat dibuka
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
		# 🔥 Cek apakah player sudah PERNAH LULUS kuis ini sebelumnya
		if Global.is_quiz_completed:
			if quiz_manager: quiz_manager.visible = false
			if text_label:
				text_label.visible = true
				SubtitleUi.show_typewriter_text("Kamu sudah menyelesaikan kuis ini dan mendapatkan sertifikat!")
			if background_sprite and certificate_tablet_bg:
				background_sprite.texture = certificate_tablet_bg
		else:
			# Jika belum pernah lulus, jalankan kuis secara normal
			if text_label: text_label.visible = false
			quiz_manager.start_quiz() 
	else:
		# Logika untuk tablet data/log laboratorium biasa (Bukan Kuis)
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
	if player:
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
	if passed:
		# 🔥 BARU: Simpan status permanen kalau pemain LULUS kuis
		Global.is_quiz_completed = true
		
		if background_sprite and certificate_tablet_bg:
			background_sprite.texture = certificate_tablet_bg
