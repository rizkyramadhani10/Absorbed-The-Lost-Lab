extends Node2D
@onready var player = $Player

# 2 Baris pertama yang muncul otomatis di awal game (Format: Dictionary)
var intro_monologues: Array[Dictionary] = [
	{
		"text": "[b][color=red]Protokol Lockdown aktif[/color][/b]",
		"duration": 3
	},
	{
		"text": "Akses menuju Workspace dikunci otomatis karena terdeteksi kontaminasi tumpahan limbah Bahan Berbahaya dan Beracun (B3) di area Second Lab",
		"duration": 6.0
	},
	{
		"text": "Sterilisasi area diperlukan untuk membuka kunci",
		"duration": 3.5
	},
]

func _ready() -> void:
	print("Spawn point yang diterima dari Global: ", Global.spawn_point)
	
	add_to_group("game")
	
	# 🔥 Pindahkan posisi player secara instan saat scene dimuat
	setup_second_lab_spawns()
	
	# 🔥 Langsung putar intro tanpa menunggu delay 1 detik
	for item in intro_monologues:
		SubtitleUi.show_typewriter_text(item["text"], "ai")
		await get_tree().create_timer(item["duration"]).timeout
		
	# Kosongkan teks setelah intro selesai
	SubtitleUi.show_typewriter_text("")

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
