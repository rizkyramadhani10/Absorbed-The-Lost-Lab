extends Area2D

# --- KONFIGURASI INSPECTOR ---
@export_group("Story Settings")
# 🔒 Stage minimal yang harus dicapai agar kayu bisa diambil
@export var required_stage: GameState.StoryStage = GameState.StoryStage.BACK_TO_LAB 

# 🔥 TAMBAHAN: Variabel untuk memajukan progres cerita setelah kayu diambil
@export var advance_story_to: GameState.StoryStage = GameState.StoryStage.POST_SHOWER 

# --- REFERENSI NODE INTERNAL ---
@onready var interact_label: Node = $Label if has_node("Label") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

# --- VARIABEL RUNTIME ---
var player_ref: Node2D = null
var is_collected: bool = false

func _ready() -> void:
	# Cek apakah kayu sudah diambil sebelumnya
	if Global.has_wood == true:
		# 🔥 Tunda 1 frame agar Node lain (seperti LevelManager) selesai _ready()
		await get_tree().process_frame
		
		# 🔥 Majukan progres cerita jika kayu sudah pernah diambil tapi stage masih tertinggal
		if GameState.current_stage < advance_story_to:
			GameState.current_stage = advance_story_to
			print("Progres cerita diperbarui ke: ", GameState.current_stage)
			
		if collision_shape:
			collision_shape.disabled = true
		queue_free()
		return
	
	# Hubungkan sinyal area untuk mendeteksi player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	show_interact_prompt(false)

# --- PENANGANAN AREA / PLAYER DETEKSI ---
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		# 🔒 JIKA BELUM MENCAPAI STAGE CERITA, ABAIKAN DETEKSI (Prompt tidak muncul)
		if GameState.current_stage < required_stage:
			print("Kayu dikunci. Butuh stage: ", required_stage)
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
	# 🔒 Filter keamanan ganda jika stage belum mencukupi saat ditekan
	if GameState.current_stage < required_stage:
		print("Interaksi ditolak: Progres cerita belum mencapai ", required_stage)
		return

	# Cek apakah sudah diambil
	if is_collected:
		return
	
	# Cek apakah player masih di dekat
	if player_ref == null:
		return
	
	# Ambil kayu
	is_collected = true
	Global.has_wood = true
	print("Kayu berhasil diambil!")
	
	# 🔥 MAJUKAN PROGRES CERITA
	if GameState.current_stage < advance_story_to:
		GameState.current_stage = advance_story_to
		print("Progres cerita diperbarui ke: ", GameState.current_stage)
	
	# Sembunyikan prompt
	show_interact_prompt(false)
	
	# Bersihkan referensi dari player sebelum objek dihancurkan agar tidak error
	if player_ref and player_ref.get("nearby_interactable") == self:
		player_ref.nearby_interactable = null
	
	# Hapus objek dari scene menggunakan set_deferred agar aman di physics frame
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	queue_free()
