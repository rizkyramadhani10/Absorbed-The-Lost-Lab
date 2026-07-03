extends Node2D
@onready var player = $Player

# 2 Baris pertama yang muncul otomatis di awal game (Format: Dictionary)
var intro_monologues: Array[Dictionary] = [
	{
		"text": "Sistem komunikasi darurat di [b]Main Lab[/b] mati... Aku harus segera ke ruang kerja ku melewati [b][color=yellow]Second Lab[/color][/b] di sebelah kiri untuk menghubungi pusat kota [b]Vosier[/b]!",
		"duration": 5.5 # Tampil selama 4.5 detik
	},
	{
		"text": "Mereka harus tahu kalau eksperimen ini mengalami kecelakaan besar..",
		"duration": 4.0 # Kalimat lebih panjang, tampil lebih lama (7 detik)
	}
]

func _ready():
	add_to_group("game")
	
	# 1. Tunggu 1 detik setelah scene game masuk
	await get_tree().create_timer(1.0).timeout
	
	# 2. Putar intro. Loop sekarang membaca key "text" dan "duration" dari dictionary
	for item in intro_monologues:
		SubtitleUi.show_typewriter_text(item["text"], "xeno")
		await get_tree().create_timer(item["duration"]).timeout
		
	# Kosongkan teks setelah intro selesai
	SubtitleUi.show_typewriter_text("")
