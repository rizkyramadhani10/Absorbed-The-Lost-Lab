extends Area2D

# --- KONFIGURASI INSPECTOR ---
@export_group("Story Settings")
# 🔒 Stage minimal yang harus dicapai
@export var required_stage: GameState.StoryStage = GameState.StoryStage.BACK_TO_LAB
# 🌟 NEW: Dropdown untuk memilih stage selanjutnya setelah dialog selesai
@export var advance_to_stage: GameState.StoryStage = GameState.StoryStage.BACK_TO_LAB
# 🔥 NEW: Syarat jumlah pengetahuan untuk membuka komputer ini
@export var required_knowledge: int = 13

@export_group("Interaction States")
# Flag untuk menyimpan progres interaksi pertama (Dialog)
@export var first_interaction_flag: String = "is_dialog_completed"
# Flag untuk menyimpan progres interaksi kedua (Quiz)
@export var quiz_completion_flag: String = "is_quiz_completed"

@export_group("Dialogue Settings (Phase 1)")
@export var gunakan_dialog: bool = false

@export_group("Quiz Settings (Phase 2)")
@export var quiz_scene: PackedScene = null
@export var game_world: Node = null
@export var quiz_text: String = "Memuat quiz..."

@export_group("Knowledge Settings")
@export var knowledge_key: String = ""

# --- REFERENSI NODE INTERNAL ---
@onready var dialog_player: DialogPlayer = $DialogPlayer if has_node("DialogPlayer") else null
@onready var interact_label: Node = $Label if has_node("Label") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

# --- VARIABEL RUNTIME ---
var player_ref: Node2D = null
var is_knowledge_unlocked: bool = false
var interaction_phase: int = 1
var quiz_instance = null

func _ready() -> void:
	# 1. Jika quiz sudah pernah diselesaikan, matikan interaksi sepenuhnya
	if Global.get(quiz_completion_flag) == true:
		_disable_interactable()
		return
		
	# 2. Jika dialog sudah pernah diselesaikan, set alat ini langsung ke Fase 2 (Quiz)
	if Global.get(first_interaction_flag) == true:
		interaction_phase = 2
		
	# 3. Cek pengetahuan
	if knowledge_key != "" and Global.knowledge_unlocked.has(knowledge_key):
		if Global.knowledge_unlocked[knowledge_key] == true:
			is_knowledge_unlocked = true

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if dialog_player:
		dialog_player.dialog_ended.connect(_on_dialog_ended)
		
	show_interact_prompt(false)

# --- PENANGANAN AREA / PLAYER DETEKSI ---
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		if GameState.current_stage < required_stage:
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
	# 1. Cek urutan cerita terlebih dahulu
	if GameState.current_stage < required_stage:
		print("Interaksi ditolak: Progres belum mencapai ", required_stage)
		SubtitleUi.show_typewriter_text("Aku harus menyelesaikan urusanku sebelumnya.")
		return
		
	# 🔥 2. CEK JUMLAH PENGETAHUAN YANG TERKUMPUL
	var collected_knowledge = 0
	for key in Global.knowledge_unlocked:
		if Global.knowledge_unlocked[key] == true:
			collected_knowledge += 1
			
	# Jika jumlahnya masih di bawah syarat (13), tolak interaksi dan tampilkan pesan
	if collected_knowledge < required_knowledge:
		SubtitleUi.show_typewriter_text("Tindakanku bisa berbahaya jika aku belum membaca semua panduan alat di lab ini (" + str(collected_knowledge) + "/" + str(required_knowledge) + ").")
		return

	# 3. Cek apakah ada dialog lain yang sedang berjalan
	var dialog_box_aktif = get_tree().current_scene.find_child("DialogueBoxes", true, false)
	if dialog_box_aktif:
		return

	# 4. Routing interaksi berdasarkan fase saat ini
	if interaction_phase == 1:
		_jalankan_interaksi_pertama()
	elif interaction_phase == 2:
		_jalankan_interaksi_kedua_quiz()

func _jalankan_interaksi_pertama() -> void:
	if gunakan_dialog and dialog_player:
		print("Fase 1: Memicu dialog internal")
		dialog_player.start()
	else:
		_on_dialog_ended()

func _jalankan_interaksi_kedua_quiz() -> void:
	print("Fase 2: Memunculkan UI Quiz")
	
	if quiz_scene == null or game_world == null:
		print("ERROR: quiz_scene atau game_world belum di-drag ke Inspector!")
		return
		
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
		
	if quiz_instance == null:
		quiz_instance = quiz_scene.instantiate()
		get_tree().root.add_child(quiz_instance)
	
	if "whiteboard_text" in quiz_instance:
		quiz_instance.whiteboard_text = quiz_text
	elif "tablet_text" in quiz_instance:
		quiz_instance.tablet_text = quiz_text
		
	quiz_instance.open(game_world, player)

# --- CALLBACK JIKA DIALOG SELESAI ---
func _on_dialog_ended() -> void:
	print("Dialog selesai.")
	
	# 1. Advance GameState menggunakan parameter dropdown baru
	GameState.current_stage = advance_to_stage
	print("GameState berhasil diubah ke: ", advance_to_stage)
	
	# 2. Buka knowledge lab
	_unlock_knowledge()
	
	# 3. Simpan state dialog selesai
	if first_interaction_flag != "":
		Global.set(first_interaction_flag, true)
	
	# 4. Ubah fase agar klik selanjutnya membuka quiz
	interaction_phase = 2
	print("Alat ini sekarang masuk ke Fase Quiz.")

# --- FUNGSI UNTUK MEMBUKA PENGETAHUAN ---
func _unlock_knowledge() -> void:
	if knowledge_key == "" or is_knowledge_unlocked:
		return
	
	if Global.knowledge_unlocked.has(knowledge_key):
		Global.knowledge_unlocked[knowledge_key] = true
		is_knowledge_unlocked = true
		print("🔓 Pengetahuan '", knowledge_key, "' terbuka!")

func _disable_interactable() -> void:
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	show_interact_prompt(false)
	if player_ref and player_ref.get("nearby_interactable") == self:
		player_ref.nearby_interactable = null
