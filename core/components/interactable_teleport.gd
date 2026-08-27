extends Area2D

# Kamu bisa mengubah target scene langsung dari Inspector untuk setiap objek yang berbeda
@export_file("*.tscn") var target_scene_path: String = ""
var player_ref: Node2D = null

func _ready() -> void:
	# Sambungkan signal area deteksi untuk Player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Pastikan petunjuk interaksi (Label) tersembunyi di awal game
	show_interact_prompt(false)

func show_interact_prompt(show: bool) -> void:
	# Mengambil node bernama "Label" yang ada di bawah root Area2D ini
	var prompt = get_node_or_null("Label")
	if prompt:
		prompt.visible = show

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_ref = body # Simpan referensi Player
		if "nearby_interactable" in body:
			body.nearby_interactable = self
		show_interact_prompt(true)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_ref = null # Hapus referensi saat player menjauh
		if "nearby_interactable" in body and body.nearby_interactable == self:
			body.nearby_interactable = null
		show_interact_prompt(false)

func interact() -> void:
	if Global.limbah_minigame_completed:
		print("Minigame ini sudah diselesaikan!")
		return

	if target_scene_path == "":
		print("ERROR: Target scene kosong!")
		return
		
	# 🔥 1. CATAT SCENE MAP DAN POSISI KOORDINAT PLAYER SEBELUM PINDAH
	Global.scene_asal_path = get_tree().current_scene.scene_file_path
	
	if player_ref:
		Global.player_last_position = player_ref.global_position
		print("Menyimpan posisi terakhir Player: ", Global.player_last_position)
	
	var error_code = get_tree().change_scene_to_file(target_scene_path)
	if error_code != OK:
		print("ERROR: Gagal pindah scene.")
