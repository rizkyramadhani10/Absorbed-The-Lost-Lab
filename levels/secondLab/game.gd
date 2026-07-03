extends Node2D
@onready var player = $Player

# 2 Baris pertama yang muncul otomatis di awal game (Format: Dictionary)
var intro_monologues: Array[Dictionary] = [
	{
		"text": "[b][color=red]Protokol Lockdown aktif[/color][/b]",
		"duration": 3 # Tampil selama 4.5 detik
	},
	{
		"text": "Akses menuju Workspace dikunci otomatis karena terdeteksi kontaminasi tumpahan limbah Bahan Berbahaya dan Beracun (B3) di area Second Lab",
		"duration": 6.0 # Kalimat lebih panjang, tampil lebih lama (7 detik)
	},
	{
		"text": "Sterilisasi area diperlukan untuk membuka kunci",
		"duration": 3.5 # Kalimat lebih panjang, tampil lebih lama (7 detik)
	},
]

func _ready():
	add_to_group("game")
	
	# 1. Tunggu 1 detik setelah scene game masuk
	await get_tree().create_timer(1.0).timeout
	
	# 2. Putar intro. Loop sekarang membaca key "text" dan "duration" dari dictionary
	for item in intro_monologues:
		SubtitleUi.show_typewriter_text(item["text"], "ai")
		await get_tree().create_timer(item["duration"]).timeout
		
	# Kosongkan teks setelah intro selesai
	SubtitleUi.show_typewriter_text("")
