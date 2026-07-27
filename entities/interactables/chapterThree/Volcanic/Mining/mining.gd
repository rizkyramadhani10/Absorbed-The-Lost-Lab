extends Area2D

signal mining_started

# 🔥 EXPORT: Path ke scene mining (bisa diatur dari inspektor)
@export var mining_scene: PackedScene = null

# Referensi ke player
var player = null
var is_player_nearby = false

func _ready():
	# Hubungkan signal
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Tambahkan ke grup untuk deteksi
	add_to_group("interactable")
	
	# Validasi
	if mining_scene == null:
		print("WARNING: Mining scene belum di-set di inspektor!")

func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body
		is_player_nearby = true
		# Beri tahu player bahwa ada objek interaktif di dekatnya
		body.nearby_interactable = self
		print("Player mendekati area mining!")

func _on_body_exited(body):
	if body.is_in_group("player") and body == player:
		is_player_nearby = false
		# Hapus referensi jika player menjauh
		if body.nearby_interactable == self:
			body.nearby_interactable = null
		player = null
		print("Player menjauh dari area mining!")

# Fungsi ini dipanggil oleh player saat interaksi
func interact():
	if is_player_nearby and player:
		print("Memulai mini game mining!")
		# Pindah ke scene mining
		_change_to_mining_scene()

func _change_to_mining_scene():
	# 🔥 SIMPAN POSISI & ARAH HADAP SEBELUM PINDAH SCENE
	if player:
		Global.player_last_position = player.global_position
		Global.player_last_flip = player.animated_sprite.flip_h
	
	# 🔥 Gunakan PackedScene yang sudah di-export
	if mining_scene != null:
		get_tree().change_scene_to_packed(mining_scene)
	else:
		print("ERROR: Mining scene tidak ditemukan! Silakan set di inspektor.")
