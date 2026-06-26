extends Area2D

@export_file("*.tscn") var target_scene_path: String = "res://levels/minigames/tabungReaksi/game.tscn"

func _ready():
	# 🔥 Cek apakah minigame sudah pernah diselesaikan via Global Autoload
	if Global.is_heating_completed:
		# Matikan area collision agar tidak mendeteksi Player lagi
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = true
		
		# Pastikan prompt teks/label sembunyi
		show_interact_prompt(false)
		return # Stop di sini, tidak perlu menyambungkan signal entri player

	# Jika belum selesai, jalankan fungsi interaksi normal seperti biasa
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	show_interact_prompt(false)

func _on_body_entered(body):
	if body.name == "Player":
		body.nearby_interactable = self
		show_interact_prompt(true)

func _on_body_exited(body):
	if body.name == "Player":
		if body.nearby_interactable == self:
			body.nearby_interactable = null
		show_interact_prompt(false)

func show_interact_prompt(show: bool):
	# Mencari node bernama "Label" sesuai dengan gambar Scene Tree kamu
	var prompt = $Label if has_node("Label") else null
	if prompt:
		prompt.visible = show

func interact():
	# Pengaman berlapis jika fungsi dipanggil paksa lewat skrip lain
	if Global.is_heating_completed:
		print("Interaksi ditolak: Alat ini sudah sukses digunakan!")
		return

	print("Interaksi dengan alat kimia, bersiap pindah scene...")
	if target_scene_path == "":
		print("ERROR: Path target scene kosong! Isi di Inspector.")
		return
		
	var error_code = get_tree().change_scene_to_file(target_scene_path)
	if error_code != OK:
		print("ERROR: Gagal pindah scene. Kode Error: ", error_code)
