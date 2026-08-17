extends Area2D

@export_file("*.tscn") var target_scene_path: String = "res://levels/minigames/tabungReaksi/game.tscn"

# 🔥 Variabel untuk menyimpan referensi player saat mendekati rak
var player_ref: Node2D = null

func _ready():
	# 🔥 Cek apakah minigame sudah pernah diselesaikan via Global Autoload
	if Global.minigame_penataan_completed:
		# Matikan area collision agar tidak mendeteksi Player lagi
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = true
		
		# Pastikan prompt teks/label sembunyi
		show_interact_prompt(false)
		return 

	# Jika belum selesai, jalankan fungsi interaksi normal seperti biasa
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	show_interact_prompt(false)

func _on_body_entered(body):
	if body.name == "Player":
		player_ref = body # 🔥 Simpan referensi player
		body.nearby_interactable = self
		show_interact_prompt(true)

func _on_body_exited(body):
	if body.name == "Player":
		player_ref = null # 🔥 Reset referensi player
		if body.nearby_interactable == self:
			body.nearby_interactable = null
		show_interact_prompt(false)

func show_interact_prompt(show: bool):
	var prompt = $Label if has_node("Label") else null
	if prompt:
		prompt.visible = show

func interact():
	# 🔥 FIX: Gunakan variabel milik minigame penyimpanan sendiri (bukan milik Shower)
	if Global.minigame_penataan_completed:
		print("Interaksi ditolak: Minigame ini sudah selesai!")
		return

	print("Interaksi dengan rak penyimpanan, bersiap pindah scene...")
	if target_scene_path == "":
		print("ERROR: Path target scene kosong! Isi di Inspector.")
		return
	
	# 🔥 TAMBAHIN PENCATAT POSISI: Biar pas balik dari minigame posisi & arah hadap bener
	Global.scene_asal_path = get_tree().current_scene.scene_file_path
	if player_ref:
		Global.player_last_position = player_ref.global_position
		Global.player_last_flip = player_ref.animated_sprite.flip_h
		
	var error_code = get_tree().change_scene_to_file(target_scene_path)
	if error_code != OK:
		print("ERROR: Gagal pindah scene. Kode Error: ", error_code)
