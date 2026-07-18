extends Node2D
@onready var player = $Player

# 2 Baris pertama yang muncul otomatis di awal game (Format: Dictionary)
var intro_monologues: Array[Dictionary] = [
	{
		"text": "Sistem komunikasi darurat di [b]Main Lab[/b] mati... Aku harus segera ke ruang kerja ku melewati [b][color=yellow]Second Lab[/color][/b] di sebelah kiri untuk menghubungi pusat kota [b]Vosier[/b]!",
		"duration": 5.5
	},
	{
		"text": "Mereka harus tahu kalau eksperimen ini mengalami kecelakaan besar..",
		"duration": 4.0
	}
]

func _ready() -> void:
	print("Spawn point yang diterima dari Global di Third Lab: ", Global.spawn_point)
	
	add_to_group("game")
	
	# 🔥 Pindahkan posisi player secara instan saat scene dimuat (Tanpa delay)
	setup_third_lab_spawns()
	
	# 🔥 Langsung putar intro tanpa menunggu delay 1 detik
	for item in intro_monologues:
		SubtitleUi.show_typewriter_text(item["text"], "xeno")
		await get_tree().create_timer(item["duration"]).timeout
		
	# Kosongkan teks setelah intro selesai
	SubtitleUi.show_typewriter_text("")

# Fungsi untuk mengatur posisi spawn Player secara aman dan instan di Third Lab
func setup_third_lab_spawns() -> void:
	if Global.spawn_point == "SpawnFromSecondLab":
		if has_node("SpawnFromSecondLab"):
			# Menggunakan set_deferred agar posisi diubah tepat di frame pertama tanpa delay visual
			player.set_deferred("global_position", $SpawnFromSecondLab.global_position)
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromSecondLab!")
		else:
			print("ERROR di Third Lab: Marker 'SpawnFromSecondLab' tidak ditemukan di Scene Tree!")
			
	elif Global.spawn_point == "SpawnFromStorage":
		if has_node("SpawnFromStorage"):
			player.set_deferred("global_position", $SpawnFromStorage.global_position)
			print("Level: Player berhasil dipindahkan ke SpawnFromStorage!")
		else:
			print("ERROR: Marker 'SpawnFromStorage' tidak ditemukan di Scene Tree!")
	elif Global.spawn_point == "SpawnFromMeadow":
		if has_node("SpawnFromMeadow"):
			# Menggunakan set_deferred agar posisi diubah tepat di frame pertama tanpa delay visual
			player.set_deferred("global_position", $SpawnFromMeadow.global_position)
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromMeadow!")
		else:
			print("ERROR di Meawdow: Marker 'SpawnFromMeadow' tidak ditemukan di Scene Tree!")
