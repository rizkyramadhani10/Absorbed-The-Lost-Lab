extends Area2D

# --- KONFIGURASI INSPECTOR ---
@export_group("Story Settings")
# 🔒 Stage minimal yang harus dicapai agar alat ini bisa diinteraksi
@export var required_stage: GameState.StoryStage = GameState.StoryStage.BACK_TO_LAB 

# 🔥 TAMBAHAN: Variabel untuk memajukan progres cerita setelah selesai
@export var advance_story_to: GameState.StoryStage = GameState.StoryStage.POST_SHOWER 

@export_group("Mini-game Settings")
@export_file("*.tscn") var target_scene_path: String = ""
@export var completion_flag: String = "is_check_monitor" 

@export_group("Dialogue Settings")
@export var gunakan_dialog: bool = false 

# --- REFERENSI NODE INTERNAL ---
@onready var dialog_player: DialogPlayer = $DialogPlayer if has_node("DialogPlayer") else null
@onready var interact_label: Node = $Label if has_node("Label") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

# --- VARIABEL RUNTIME ---
var player_ref: Node2D = null

func _ready() -> void:
	if Global.get(completion_flag) == true:
		
		# 🔥 Tunda 1 frame agar Node lain (seperti LevelManager) selesai _ready()
		await get_tree().process_frame
		
		# 🔥 Majukan progres cerita jika belum mencapai target stage
		if GameState.current_stage < advance_story_to:
			GameState.current_stage = advance_story_to
			print("Progres cerita diperbarui ke: ", GameState.current_stage)
			
		if collision_shape:
			collision_shape.disabled = true
		show_interact_prompt(false)
		
		# 🔥 Baterai langsung dihapus saat player masuk ke scene jika statusnya sudah diambil
		queue_free()
		return 

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if dialog_player:
		dialog_player.dialog_ended.connect(_on_dialog_ended)
		
	show_interact_prompt(false)

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

func interact() -> void:
	# 🔒 Filter keamanan ganda jika stage belum mencukupi saat ditekan
	if GameState.current_stage < required_stage:
		print("Interaksi ditolak: Progres cerita belum mencapai ", required_stage)
		return

	if Global.get(completion_flag) == true:
		print("Interaksi ditolak: Alat ini sudah sukses digunakan!")
		return

	var dialog_box_aktif = get_tree().current_scene.find_child("DialogueBoxes", true, false)
	if dialog_box_aktif:
		return

	if gunakan_dialog and dialog_player:
		print("Memicu dialog internal untuk alat: ", name)
		dialog_player.start()
		return 

	_ganti_ke_scene_minigame()
	
	# Jika tidak pakai dialog dan tidak pindah scene, langsung selesaikan secara instan
	if target_scene_path == "" and not gunakan_dialog:
		Global.set(completion_flag, true)
		
		if GameState.current_stage < advance_story_to:
			GameState.current_stage = advance_story_to
			print("Progres cerita diperbarui ke: ", GameState.current_stage)
			
		# 🔥 FIX: Sembunyikan label, matikan collision, & bersihkan referensi player
		show_interact_prompt(false)
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		if player_ref and player_ref.get("nearby_interactable") == self:
			player_ref.nearby_interactable = null
			
		# 🔥 Hapus baterai dari scene saat diambil (tanpa dialog)
		queue_free()

func _on_dialog_ended() -> void:
	print("Dialog untuk ", name, " telah selesai.")
	
	if completion_flag != "":
		Global.set(completion_flag, true)
		print("Status ", completion_flag, " sekarang TRUE")
		
		if GameState.current_stage < advance_story_to:
			GameState.current_stage = advance_story_to
			print("Progres cerita diperbarui ke: ", GameState.current_stage)
	
	# 🔥 FIX: Sembunyikan label, matikan collision, & bersihkan referensi player setelah dialog
	show_interact_prompt(false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if player_ref and player_ref.get("nearby_interactable") == self:
		player_ref.nearby_interactable = null
		
	# 🔥 Hapus baterai dari scene setelah dialog selesai
	queue_free()
			
	if target_scene_path != "":
		_ganti_ke_scene_minigame()

func _ganti_ke_scene_minigame() -> void:
	if target_scene_path == "":
		return
	
	Global.scene_asal_path = get_tree().current_scene.scene_file_path
	if player_ref:
		Global.player_last_position = player_ref.global_position
		if player_ref.has_node("AnimatedSprite2D"):
			Global.player_last_flip = player_ref.get_node("AnimatedSprite2D").flip_h
		elif "animated_sprite" in player_ref and player_ref.animated_sprite:
			Global.player_last_flip = player_ref.animated_sprite.flip_h
		
	var error_code = get_tree().change_scene_to_file(target_scene_path)
	if error_code != OK:
		print("ERROR: Gagal pindah scene. Kode Error: ", error_code)
