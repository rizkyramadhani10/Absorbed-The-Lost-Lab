extends Control

@onready var player = $Player

func _ready() -> void:
	print("Spawn point yang diterima dari Global: ", Global.spawn_point)
	
	add_to_group("game")
	
	setup_level_spawns()
	

# TAMBAHAN: Fungsi untuk mengatur posisi spawn Player secara aman dan instan
func setup_level_spawns() -> void:
	if Global.spawn_point == "SpawnFromThirdLab":
		if has_node("SpawnFromThirdLab"):
			# Menggunakan set_deferred agar posisi diubah tepat di frame pertama tanpa delay visual
			player.set_deferred("global_position", $SpawnFromThirdLab.global_position)
			print("Level: Player berhasil dipindahkan ke SpawnFromThirdLab!")
		else:
			print("ERROR: Marker 'SpawnFromThirdLab' tidak ditemukan di Scene Tree!")
