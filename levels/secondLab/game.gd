extends Node2D
@onready var player = $Player
@onready var dialog_player : DialogPlayer = $DialogPlayer

func _ready() -> void:
	print("Spawn point yang diterima dari Global: ", Global.spawn_point)
	add_to_group("game")

# Fungsi untuk mengatur posisi spawn Player secara aman dan instan
func setup_second_lab_spawns() -> void:
	if Global.spawn_point == "SpawnFromWorkspace":
		if has_node("SpawnFromWorkspace"):
			# Menggunakan set_deferred agar posisi diubah tepat di frame pertama tanpa delay visual
			player.set_deferred("global_position", $SpawnFromWorkspace.global_position)
			print("Second Lab: Player berhasil dipindahkan ke SpawnFromWorkspace!")
		else:
			print("ERROR di Second Lab: Marker 'SpawnFromWorkspace' tidak ditemukan di Scene Tree!")
			
	elif Global.spawn_point == "SpawnFromThirdLab":
		if has_node("SpawnFromThirdLab"):
			player.set_deferred("global_position", $SpawnFromThirdLab.global_position)
			print("Second Lab: Player berhasil dipindahkan ke SpawnFromThirdLab!")
		else:
			print("ERROR di Second Lab: Marker 'SpawnFromThirdLab' tidak ditemukan di Scene Tree!")
