extends Area2D

# --- KONFIGURASI INSPECTOR ---
@export_group("Story Settings")
# 🔒 Stage minimal yang harus dicapai agar alat ini bisa diinteraksi (Default: BACK_TO_LAB)
@export var required_stage: GameState.StoryStage = GameState.StoryStage.BACK_TO_LAB

@export_group("Mini-game Settings")
@export_file("*.tscn") var target_scene_path: String = ""
@export var completion_flag: String = "is_heating_completed" 

@export_group("Dialogue Settings")
# 🔥 Centang ini di Inspector jika alat ini memiliki DialogPlayer yang aktif!
@export var gunakan_dialog: bool = false 

# --- REFERENSI NODE INTERNAL ---
@onready var dialog_player: DialogPlayer = $DialogPlayer if has_node("DialogPlayer") else null
@onready var interact_label: Node = $Label if has_node("Label") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

# --- VARIABEL RUNTIME ---
var player_ref: Node2D = null

func _ready() -> void:
	# 1. Cek secara dinamis apakah alat ini sudah selesai dikerjakan sebelumnya
	if Global.get(completion_flag) == true:
		if collision_shape:
			collision_shape.disabled = true
		show_interact_prompt(false)
		return 

	# 2. Hubungkan sinyal area untuk mendeteksi player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 3. Hubungkan sinyal dari DialogPlayer lokal jika interaksi membutuhkan perpindahan scene setelah dialog selesai
	if dialog_player:
		dialog_player.dialog_ended.connect(_on_dialog_ended)
		
	show_interact_prompt(false)

# --- PENANGANAN AREA / PLAYER DETEKSI ---
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		# 🔒 JIKA BELUM MENCAPAI STAGE CERITA, ABAIKAN DETEKSI (Prompt tidak muncul)
		if GameState.current_stage < required_stage:
			print("Alat '", name, "' dikunci. Butuh stage: ", required_stage)
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
	# 🔒 1. Filter keamanan ganda jika stage belum mencukupi
	if GameState.current_stage < required_stage:
		print("Interaksi ditolak: Progres cerita belum mencapai ", required_stage)
		return

	# 2. Lindungi jika alat sudah sukses diselesaikan
	if Global.get(completion_flag) == true:
		print("Interaksi ditolak: Alat ini sudah sukses digunakan!")
		return

	# Cek apakah bubble dialog sedang aktif/terbuka di layar agar tidak bentrok input
	var dialog_box_aktif = get_tree().current_scene.find_child("DialogueBoxes", true, false)
	if dialog_box_aktif:
		return

	# 3. Prioritas Pertama: Jalankan Dialog jika diaktifkan di Inspector
	if gunakan_dialog and dialog_player:
		print("Memicu dialog internal untuk alat: ", name)
		dialog_player.start()
		return 

	# 4. Prioritas Kedua: Jika tidak menggunakan dialog, langsung jalankan mini-game
	_ganti_ke_scene_minigame()

# --- CALLBACK JIKA DIALOG SELESAI ---
func _on_dialog_ended() -> void:
	print("Dialog untuk ", name, " telah selesai.")
	
	if completion_flag != "":
		Global.set(completion_flag, true)
	
	# Sembunyikan label & matikan area setelah alat selesai digunakan
	show_interact_prompt(false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if player_ref and player_ref.get("nearby_interactable") == self:
		player_ref.nearby_interactable = null

	if target_scene_path != "":
		_ganti_ke_scene_minigame()

# --- FUNGSI PRIVAT PERPINDAHAN SCENE ---
func _ganti_ke_scene_minigame() -> void:
	if target_scene_path == "":
		print("INFO: Objek ini hanya dekorasi atau Path target scene belum diisi di Inspector.")
		return
	
	Global.scene_asal_path = get_tree().current_scene.scene_file_path
	if player_ref:
		Global.player_last_position = player_ref.global_position
		if player_ref.has_node("AnimatedSprite2D"):
			Global.player_last_flip = player_ref.get_node("AnimatedSprite2D").flip_h
		elif "animated_sprite" in player_ref and player_ref.animated_sprite:
			Global.player_last_flip = player_ref.animated_sprite.flip_h
		
	print("Interaksi dengan alat kimia berhasil, mencatat posisi: ", Global.player_last_position)
		
	var error_code = get_tree().change_scene_to_file(target_scene_path)
	if error_code != OK:
		print("ERROR: Gagal pindah scene. Kode Error: ", error_code)
