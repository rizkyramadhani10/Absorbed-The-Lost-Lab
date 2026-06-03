extends CanvasLayer

@export var tablet_text: String = ""
@export var is_quiz_tablet: bool = false # Centang di Inspector untuk tablet kuis

var game_world: Node = null
var player: Node = null

@onready var text_label = $Panel/TxtDisplay
@onready var close_button = $CloseBtn 
@onready var quiz_manager = $QuizManager # Jalur ke QuizManager kamu

# Variabel untuk menyimpan data animasi Tween
var slide_tween: Tween

func _ready():
	visible = false
	if quiz_manager:
		quiz_manager.visible = false
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func open(world, player_node):
	game_world = world
	player = player_node
	
	if player:
		player.set_process(false)
		player.set_physics_process(false)
	
	var screen_height = get_viewport().get_visible_rect().size.y
	
	# Set posisi awal layer ke bawah layar (tidak terlihat)
	offset.y = screen_height
	visible = true
	
	# Jalankan animasi Slide Up (Pop Up)
	if slide_tween and slide_tween.is_running():
		slide_tween.kill() 
		
	slide_tween = create_tween()
	slide_tween.tween_property(self, "offset:y", 0.0, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# Sistem pengecekan tipe kuis atau dokumen biasa
	if is_quiz_tablet and quiz_manager:
		if text_label:
			text_label.visible = false
		quiz_manager.start_quiz()  # Jalankan kuis!
	else:
		if text_label:
			text_label.visible = true
			if tablet_text != null and tablet_text != "":
				SubtitleUi.show_typewriter_text(tablet_text)
			else:
				SubtitleUi.show_typewriter_text("Tablet tidak berisi data.")

func close():
	var screen_height = get_viewport().get_visible_rect().size.y
	
	# Jalankan animasi Slide Down ke bawah layar
	if slide_tween and slide_tween.is_running():
		slide_tween.kill()
		
	slide_tween = create_tween()
	slide_tween.tween_property(self, "offset:y", screen_height, 0.3)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
		
	# Tunggu sampai animasi meluncur turun selesai baru hilangkan UI
	await slide_tween.finished
	
	if game_world:
		game_world.visible = true
	if player:
		player.set_process(true)
		player.set_physics_process(true)
	
	visible = false
	game_world = null
	player = null

# === FUNGSI YANG TADI HILANG / ERROR ===
func _on_close_pressed():
	close()

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		close()
