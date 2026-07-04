extends Node2D

@onready var player = $Player

# 2 Baris pertama yang muncul otomatis di awal game (Format: Dictionary)
var intro_monologues: Array[Dictionary] = [
	{
		"text": "Aku ingin membuat beberapa Racikan Cairan Kronos sekarang juga untuk menstabilkan inti mesin waktu ini...",
		"duration": 6.0
	},
	{
		"text": "Tunggu, sebagai seorang ilmuwan, aku harus memastikan aku memakai APD (Alat Pelindung Diri) sesuai dengan aturan K3 di laboratorium! Mengubah sejarah bukan alasan untuk mengabaikan keselamatan.",
		"duration": 9.0
	}
]

# Sisa baris teks setelah pakai APD dengan durasi yang bisa kamu atur sendiri
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
	print("Spawn point yang diterima dari Global: ", Global.spawn_point)
	
	add_to_group("game")
	
	setup_level_spawns()
	
	for item in intro_monologues:
		SubtitleUi.show_typewriter_text(item["text"])
		await get_tree().create_timer(item["duration"]).timeout
		
	# Kosongkan teks setelah intro selesai
	SubtitleUi.show_typewriter_text("")

# TAMBAHAN: Fungsi untuk mengatur posisi spawn Player secara aman dan instan
func setup_level_spawns() -> void:
	if Global.spawn_point == "SpawnFromThirdLab":
		if has_node("SpawnFromThirdLab"):
			# Menggunakan set_deferred agar posisi diubah tepat di frame pertama tanpa delay visual
			player.set_deferred("global_position", $SpawnFromThirdLab.global_position)
			print("Level: Player berhasil dipindahkan ke SpawnFromThirdLab!")
		else:
			print("ERROR: Marker 'SpawnFromThirdLab' tidak ditemukan di Scene Tree!")

# Fungsi ini dipanggil dari player.gd setelah baju APD terpakai
func start_apd_monologue() -> void:
	# 3. Putar teks edukasi APD dengan durasi masing-masing tanpa mengunci player
	for item in apd_monologues:
		SubtitleUi.show_typewriter_text(item["text"])
		await get_tree().create_timer(item["duration"]).timeout
		
	# Kosongkan teks jika semua monolog sudah selesai
	SubtitleUi.show_typewriter_text("")
