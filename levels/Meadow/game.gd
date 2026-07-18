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
	if Global.spawn_point == "SpawnFromThirdLab":
		if has_node("SpawnFromThirdLab"):
			# Menggunakan set_deferred agar posisi diubah tepat di frame pertama tanpa delay visual
			player.set_deferred("global_position", $SpawnFromThirdLab.global_position)
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromThirdLab!")
		else:
			print("ERROR di Meawdow: Marker 'SpawnFromThirdLab' tidak ditemukan di Scene Tree!")
	elif Global.spawn_point == "SpawnFromForest":
		if has_node("SpawnFromForest"):
			# Menggunakan set_deferred agar posisi diubah tepat di frame pertama tanpa delay visual
			player.set_deferred("global_position", $SpawnFromForest.global_position)
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromForest!")
		else:
			print("ERROR di Meawdow: Marker 'SpawnFromForest' tidak ditemukan di Scene Tree!")
