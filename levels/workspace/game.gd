extends Node2D

@onready var player = $Player

func _ready() -> void:
	add_to_group("game")
	
	# 🔥 Pindahkan posisi player secara instan saat scene dimuat
	setup_player_spawn_position()
	
# Fungsi untuk mengatur posisi spawn Player secara aman dan instan
func setup_player_spawn_position() -> void:
	# Tambahkan kurung siku '[' ']' untuk mengecek apakah ada spasi yang tidak sengaja terketik
	print("Mencoba memindahkan Player. Spawn yang diminta: [", Global.spawn_point, "]")

	if Global.spawn_point == "SpawnFromWorkspace":
		var spawn_node = get_node_or_null("SpawnFromWorkspace")
		if spawn_node:
			# 🔥 FIX: Hapus set_deferred, gunakan = secara langsung
			player.global_position = spawn_node.global_position
			print("Berhasil memindahkan player! Posisi sekarang: ", player.global_position)
			Global.spawn_point = "" # Reset agar aman
		else:
			print("ERROR: Node SpawnFromWorkspace tidak ditemukan!")

	elif Global.spawn_point == "SpawnFromSecondLab":
		var spawn_node = get_node_or_null("SpawnFromSecondLab")
		if spawn_node:
			player.global_position = spawn_node.global_position
			print("Berhasil memindahkan player! Posisi sekarang: ", player.global_position)
			Global.spawn_point = ""
		else:
			print("ERROR: Node SpawnFromSecondLab tidak ditemukan!")
			
	else:
		print("PERINGATAN: Global.spawn_point tidak dikenali, player tetap di posisi default.")
