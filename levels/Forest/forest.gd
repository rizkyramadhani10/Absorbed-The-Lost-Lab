extends Node2D
@onready var player = $Player

func _ready() -> void:
	print("Spawn point yang diterima dari Global di Third Lab: ", Global.spawn_point)
	
	add_to_group("game")
	
	# 🔥 Pindahkan posisi player secara instan saat scene dimuat (Tanpa delay)
	setup_meawdow_spawns()
		
	# Kosongkan teks setelah intro selesai
	SubtitleUi.show_typewriter_text("")

# Fungsi untuk mengatur posisi spawn Player secara aman dan instan di Third Lab
func setup_meawdow_spawns() -> void:
	if Global.spawn_point == "SpawnFromMeadow":
		if has_node("SpawnFromMeadow"):
			# Menggunakan set_deferred agar posisi diubah tepat di frame pertama tanpa delay visual
			player.set_deferred("global_position", $SpawnFromMeadow.global_position)
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromMeadow!")
		else:
			print("ERROR di Meawdow: Marker 'SpawnFromMeadow' tidak ditemukan di Scene Tree!")
