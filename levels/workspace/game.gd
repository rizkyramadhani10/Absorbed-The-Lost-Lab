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

# Teks edukasi APD
var apd_monologues: Array[Dictionary] = [
	{
		"text": "Pertama, jas laboratorium. Ini berfungsi untuk melindungi kulit dan pakaian sehari-hari kita dari percikan bahan kimia berbahaya, zat korosif, atau noda yang sulit hilang.",
		"duration": 7.5
	},
	{
		"text": "Kedua, penutup kepala atau hairnet. Ini memastikan tidak ada helai rambut yang rontok dan mengontaminasi campuran kimia sensitif kita, sekaligus menjaga rambut agar aman dari zat berbahaya.",
		"duration": 7.5
	},
	{
		"text": "Ketiga, kacamata pelindung. Mata kita tidak ada gantinya, dan goggle ini akan melindungi mata dari uap kimia yang perih, percikan cairan, atau ledakan kecil akibat tekanan reaksi.",
		"duration": 9.5
	},
	{
		"text": "Dan keempat, masker wajah. Saat mencampur senyawa volatil untuk mesin waktu, gas beracun bisa saja menguap. Masker ini berfungsi menyaring udara agar kita tidak menghirup uap berbahaya langsung ke dalam paru-paru.",
		"duration": 11.0
	},
	{
		"text": "Luar biasa! Sekarang setelah aku memakai APD lengkap dan patuh aturan K3... mari kita kembali menyelamatkan masa depan!",
		"duration": 5.0
	}
]

func _ready() -> void:
	add_to_group("game")
	
	# 🔥 Pindahkan posisi player secara instan saat scene dimuat
	setup_player_spawn_position()
	
	# 🔥 Langsung jalankan intro tanpa menunggu delay 1 detik
	for item in intro_monologues:
		SubtitleUi.show_typewriter_text(item["text"], "xeno")
		await get_tree().create_timer(item["duration"]).timeout
		
	SubtitleUi.show_typewriter_text("")

# Fungsi untuk mengatur posisi spawn Player secara aman dan instan
func setup_player_spawn_position() -> void:
	print("Mencoba memindahkan Player. Spawn yang diminta: ", Global.spawn_point)

	if Global.spawn_point == "SpawnFromWorkspace":
		if has_node("SpawnFromWorkspace"):
			# Menggunakan set_deferred agar posisi sinkron seketika di frame awal
			player.set_deferred("global_position", $SpawnFromWorkspace.global_position)
			print("Berhasil memindahkan player ke SpawnFromWorkspace!")
		else:
			print("ERROR: Node SpawnFromWorkspace tidak ditemukan!")

	elif Global.spawn_point == "SpawnFromSecondLab":
		if has_node("SpawnFromSecondLab"):
			player.set_deferred("global_position", $SpawnFromSecondLab.global_position)
			print("Berhasil memindahkan player ke SpawnFromSecondLab!")
		else:
			print("ERROR: Node SpawnFromSecondLab tidak ditemukan!")
			
	else:
		print("PERINGATAN: Global.spawn_point tidak dikenali, player tetap di posisi default.")

# Fungsi APD tetap dipertahankan
func start_apd_monologue() -> void:
	for item in apd_monologues:
		SubtitleUi.show_typewriter_text(item["text"])
		await get_tree().create_timer(item["duration"]).timeout
		
	SubtitleUi.show_typewriter_text("")
