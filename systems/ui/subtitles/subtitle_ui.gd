extends CanvasLayer

@onready var container = $MarginContainer
# Pastikan path ini sesuai dengan nama RichTextLabel di scene kamu
@onready var subtitle_label = $MarginContainer/PanelContainer/SubtitleText 

var typing_speed: float = 0.0198
var subtitle_tween: Tween # Menyimpan referensi animasi yang sedang berjalan

func _ready():
	container.hide()

func show_typewriter_text(text_to_type: String, _duration_after_typing: float = 2.5):
	# 1. Jika ada animasi teks sebelumnya yang belum selesai, "BUNUH" prosesnya segera!
	#    Ini mendepak timer teks lama agar tidak menghapus teks baru secara gaib.
	if subtitle_tween and subtitle_tween.is_valid():
		subtitle_tween.kill()
	
	# 2. Jika game.gd mengirim teks kosong "", artinya subtitel disuruh menghilang
	if text_to_type == "":
		container.hide()
		return
		
	# 3. Tampilkan layout container subtitel
	container.show()
	
	# 4. Masukkan teks baru dan sembunyikan semua huruf di awal (set ke 0)
	subtitle_label.text = text_to_type
	subtitle_label.visible_characters = 0
	
	# 5. Hitung total durasi mengetik secara dinamis berdasarkan panjang kalimat
	var total_typing_time = text_to_type.length() * typing_speed
	
	# 6. Jalankan efek mesin tik menggunakan Tween (Lebih bersih dan aman dari await biasa)
	subtitle_tween = create_tween()
	subtitle_tween.tween_property(
		subtitle_label, 
		"visible_characters", 
		text_to_type.length(), 
		total_typing_time
	)
	
	# PERUBAHAN UTAMA: Perintah 'await timer' dan 'container.hide()' di sini DIHAPUS TOTAL.
	# Sekarang boks subtitel hanya akan menutup jika game.gd memanggil fungsi ini dengan teks kosong ("").
