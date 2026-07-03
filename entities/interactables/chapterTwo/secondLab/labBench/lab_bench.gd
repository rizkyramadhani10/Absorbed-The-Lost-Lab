extends Area2D

# 1. Preload kedua tekstur (Messy & Neatly) agar siap digunakan
# 🔥 Silakan sesuaikan path "res://..." ini dengan letak file gambarmu di FileSystem
var texture_messy = preload("res://levels/secondLab/sprites/environments/MessyChem.png")
var texture_neatly = preload("res://levels/secondLab/sprites/environments/NeatlyArrangeChem.png")

@export_file("*.tscn") var target_scene_path: String = ""

@onready var chem_tools = $chemTools
@onready var collision_shape = $CollisionShape2D

var player_ref: Node2D = null

func _ready() -> void:
	# Sambungkan sinyal deteksi player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	show_interact_prompt(false)
	
	# 🔥 CEK STATUS MINIGAME UNTUK MENGUBAH VISUAL
	update_visual_meja_lab()

func update_visual_meja_lab() -> void:
	if Global.limbah_minigame_completed:
		# Jika minigame SUDAH selesai:
		if chem_tools:
			chem_tools.texture = texture_neatly # Ganti ke visual rapi
		
		# Matikan interaksi agar player tidak bisa masuk ke minigame lagi
		if collision_shape:
			collision_shape.disabled = true
			
		show_interact_prompt(false)
		print("LAB BENCH: Meja sudah rapi (neatlyChem), interaksi dinonaktifkan.")
	else:
		# Jika minigame BELUM selesai:
		if chem_tools:
			chem_tools.texture = texture_messy # Tetap gunakan visual berantakan
		print("LAB BENCH: Meja masih berantakan (messyChem), siap diinteraksi.")

func _on_body_entered(body: Node2D) -> void:
	# Sinyal ini tidak akan terpicu jika collision_shape sudah disabled (saat menang)
	if body.name == "Player":
		player_ref = body
		if "nearby_interactable" in body:
			body.nearby_interactable = self
		show_interact_prompt(true)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_ref = null
		if "nearby_interactable" in body and body.nearby_interactable == self:
			body.nearby_interactable = null
		show_interact_prompt(false)

func show_interact_prompt(show: bool) -> void:
	var prompt = get_node_or_null("Label")
	if prompt:
		prompt.visible = show

func interact() -> void:
	# Pengaman jika fungsi dipanggil paksa
	if Global.limbah_minigame_completed:
		return

	if target_scene_path == "":
		print("ERROR: Target scene belum diatur di Inspector!")
		return
		
	# Catat scene map saat ini dan posisi terakhir player
	Global.scene_asal_path = get_tree().current_scene.scene_file_path
	if player_ref:
		Global.player_last_position = player_ref.global_position
	
	var error_code = get_tree().change_scene_to_file(target_scene_path)
	if error_code != OK:
		print("ERROR: Gagal pindah scene. Kode Error: ", error_code)
