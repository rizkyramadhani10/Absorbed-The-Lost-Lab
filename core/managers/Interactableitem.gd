extends Area2D

# --- KONFIGURASI INSPECTOR ---
@export_group("Story Settings")
# 🔒 Stage minimal yang harus dicapai agar alat ini bisa diinteraksi
@export var required_stage: GameState.StoryStage = GameState.StoryStage.BACK_TO_LAB

@export_group("Mini-game Settings")
@export_file("*.tscn") var target_scene_path: String = ""
@export var completion_flag: String = "is_heating_completed"

@export_group("Dialogue Settings")
# 🔥 Centang ini di Inspector jika alat ini memiliki DialogPlayer yang aktif!
@export var gunakan_dialog: bool = false

@export_group("Knowledge Settings")
# 🔥 MASUKKAN KEY UNTUK PENGETAHUAN DI TABLET
@export var knowledge_key: String = ""

# --- REFERENSI NODE INTERNAL ---
@onready var dialog_player: DialogPlayer = $DialogPlayer if has_node("DialogPlayer") else null
@onready var interact_label: Node = $Label if has_node("Label") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

# --- VARIABEL RUNTIME ---
var player_ref: Node2D = null
var is_knowledge_unlocked: bool = false

func _ready() -> void:
	# Cek apakah pengetahuan sudah terbuka dari save data sebelumnya
	if knowledge_key != "" and Global.knowledge_unlocked.has(knowledge_key):
		if Global.knowledge_unlocked[knowledge_key] == true:
			is_knowledge_unlocked = true
			if collision_shape:
				collision_shape.disabled = true
			show_interact_prompt(false)
			return
	
	# Cek secara dinamis apakah alat ini sudah selesai dikerjakan (untuk minigame)
	if completion_flag != "" and Global.get(completion_flag) == true:
		if collision_shape:
			collision_shape.disabled = true
		show_interact_prompt(false)
		return

	# Hubungkan sinyal area untuk mendeteksi player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if dialog_player:
		dialog_player.dialog_ended.connect(_on_dialog_ended)
		
	show_interact_prompt(false)

# --- PENANGANAN AREA / PLAYER DETEKSI ---
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		if is_knowledge_unlocked:
			return

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
	if is_knowledge_unlocked:
		return

	if GameState.current_stage < required_stage:
		return

	if completion_flag != "" and Global.get(completion_flag) == true:
		return

	var dialog_box_aktif = get_tree().current_scene.find_child("DialogueBoxes", true, false)
	if dialog_box_aktif:
		return

	# Prioritas Pertama: Jalankan Dialog
	if gunakan_dialog and dialog_player:
		dialog_player.start()
		return

	# Prioritas Kedua: Langsung jalankan mini-game / pengetahuan jika tidak ada dialog
	_on_dialog_ended()

# --- CALLBACK JIKA DIALOG SELESAI ---
func _on_dialog_ended() -> void:
	
	# Buka pengetahuan & munculkan notifikasi real-time
	_unlock_knowledge()
	
	# Pindah scene setelah dialog ditutup (jika alat ini adalah pintu masuk minigame)
	if target_scene_path != "":
		_ganti_ke_scene_minigame()

# --- FUNGSI UNTUK MEMBUKA PENGETAHUAN ---
func _unlock_knowledge() -> void:
	if knowledge_key == "" or is_knowledge_unlocked:
		return
	
	if Global.knowledge_unlocked.has(knowledge_key):
		Global.knowledge_unlocked[knowledge_key] = true
		is_knowledge_unlocked = true
		
		# 🔥 Sembunyikan label prompt & matikan area SECARA INSTAN agar tidak nyangkut
		show_interact_prompt(false)
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		if player_ref and player_ref.get("nearby_interactable") == self:
			player_ref.nearby_interactable = null
		
		# 🔥 HITUNG PROGRES REAL-TIME
		var collected_knowledge = 0
		for key in Global.knowledge_unlocked:
			if Global.knowledge_unlocked[key] == true:
				collected_knowledge += 1
				
		# 🔥 MUNCULKAN NOTIFIKASI OTOMATIS
		if collected_knowledge < 13:
			SubtitleUi.show_typewriter_text("Memori alat lab ditambahkan ke tablet. (" + str(collected_knowledge) + "/13)")
		else:
			SubtitleUi.show_typewriter_text("Semua 13 materi lab telah dipelajari! Aku harus kembali ke komputer utama.")
		
		print("🔓 Pengetahuan '", knowledge_key, "' terbuka. Total: ", collected_knowledge)
	else:
		print("ERROR: Key '", knowledge_key, "' tidak ditemukan di Global.knowledge_unlocked!")

# --- FUNGSI PRIVAT PERPINDAHAN SCENE ---
func _ganti_ke_scene_minigame() -> void:
	Global.scene_asal_path = get_tree().current_scene.scene_file_path
	
	# 🔥 Hapus pencarian marker Adestilasi. Rekam posisi karakter secara langsung dari lantai tempat dia berdiri.
	if player_ref:
		Global.player_last_position = player_ref.global_position
		
		if player_ref.has_node("AnimatedSprite2D"):
			Global.player_last_flip = player_ref.get_node("AnimatedSprite2D").flip_h
		elif "animated_sprite" in player_ref and player_ref.animated_sprite:
			Global.player_last_flip = player_ref.animated_sprite.flip_h
			
	print("Posisi murni direkam: ", Global.player_last_position)
		
	var error_code = get_tree().change_scene_to_file(target_scene_path)
	if error_code != OK:
		print("ERROR: Gagal pindah scene. Kode Error: ", error_code)
