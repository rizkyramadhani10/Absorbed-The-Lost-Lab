extends Node2D

@onready var sprite_pencapit = $Sprite2D
@onready var area_interaksi = $Area2D
@onready var progress_bar = $"../ProgressBar"
@onready var bunsen = $"../Bunsen"

var tekstur_gabungan = preload("res://assets/images/itemProps/interactableProps/bunsen/cpt_holding_tube.png")

# 📄 PATH SCENE: Target scene setelah pemanasan selesai (bisa diubah via Inspector)
@export_file("*.tscn") var main_game_scene: String = "res://levels/mainLab/game.tscn"

# Drag
var is_dragging = false
var drag_offset = Vector2.ZERO

# Tabung
var is_holding_tube = false
var over_tube_area = null
var is_heating_complete = false

# 🔥 VAR BARU: Apakah pencapit sedang menyentuh Bunsen?
var is_touching_bunsen = false

var posisi_meja : Vector2

func _ready():
	posisi_meja = global_position
	
	progress_bar.visible = false
	progress_bar.value = 0
	progress_bar.max_value = 1000
	
	z_index = 10
	
	print("SCRIPT PENCAPIT BERJALAN")
	
	if bunsen == null:
		print("ERROR: Bunsen tidak ditemukan! Pastikan node Bunsen ada di ../Bunsen")
	else:
		print("✅ Bunsen ditemukan: ", bunsen.name)
	
	area_interaksi.input_event.connect(_on_input_event)
	area_interaksi.area_entered.connect(_on_area_entered)
	area_interaksi.area_exited.connect(_on_area_exited)

func _process(delta):
	# Drag pencapit
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset
	
	# 🔥 LOGIKA PEMANASAN: Jika pencapit memegang tabung DAN menyentuh Bunsen
	if is_holding_tube and !is_heating_complete:
		progress_bar.visible = true
		
		# Cek apakah Bunsen menyala dan pencapit menyentuh area Bunsen
		if bunsen != null and is_touching_bunsen:
			var heating_speed = bunsen.get_heating_rate()
			
			if heating_speed > 0:
				progress_bar.value += heating_speed * delta
				print("📈 Progress: ", round(progress_bar.value), "/", progress_bar.max_value, " | Speed: ", heating_speed)
				
				if progress_bar.value >= progress_bar.max_value:
					progress_bar.value = progress_bar.max_value
					is_heating_complete = true
					print("✅ Pemanasan selesai! Tabung berhasil dipanaskan")
					_on_heating_complete()
			else:
				# Bunsen menyala tapi api = 0 (mati lewat slider)
				if progress_bar.value > 0:
					progress_bar.value -= 30.0 * delta
					if progress_bar.value < 0:
						progress_bar.value = 0
		else:
			# Tidak menyentuh Bunsen atau Bunsen mati
			if progress_bar.value > 0:
				progress_bar.value -= 30.0 * delta
				if progress_bar.value < 0:
					progress_bar.value = 0
	
	elif is_holding_tube and is_heating_complete:
		progress_bar.visible = true
		progress_bar.value = progress_bar.max_value
	else:
		progress_bar.visible = false

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position()

func _unhandled_input(event):
	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if !event.pressed:
			is_dragging = false
			
			# Ambil tabung
			if over_tube_area != null and over_tube_area.is_visible_in_tree() and !is_holding_tube and !is_heating_complete:
				eksekusi_gabung_tabung()
			
			# Balik ke posisi awal kalau belum bawa tabung
			if !is_holding_tube:
				global_position = posisi_meja

func eksekusi_gabung_tabung():
	is_holding_tube = true
	progress_bar.value = 0
	is_heating_complete = false
	is_touching_bunsen = false  # Reset status sentuh Bunsen
	sprite_pencapit.texture = tekstur_gabungan
	
	if over_tube_area:
		over_tube_area.visible = false
	
	print("🧪 Tabung berhasil diambil")

# 🔥 FUNGSI BARU: Deteksi collision dengan Bunsen
func _on_area_entered(area):
	print("📍 Area entered di pencapit: ", area.name, " (Parent: ", area.get_parent().name, ")")
	
	# Deteksi tabung reaksi (untuk mengambil)
	if area.name == "Tabung Reaksi":
		over_tube_area = area
		print("🧪 Tabung terdeteksi! over_tube_area = ", over_tube_area.name)
	
	# 🔥 DETEKSI BUNSEN: Jika area yang masuk adalah area Bunsen
	if area.get_parent().name == "Bunsen" and area.name == "Area2D":
		is_touching_bunsen = true
		print("🔥🔥🔥 PENCAPIT MENYENTUH BUNSEN! is_touching_bunsen = ", is_touching_bunsen)

func _on_area_exited(area):
	# Tabung reaksi meninggalkan area
	if area == over_tube_area:
		over_tube_area = null
		print("🧪 Tabung meninggalkan area")
	
	# 🔥 PENCAPIT MENINGGALKAN BUNSEN
	if area.get_parent().name == "Bunsen" and area.name == "Area2D":
		is_touching_bunsen = false
		print("❌ Pencapit meninggalkan Bunsen! is_touching_bunsen = ", is_touching_bunsen)

# 🔄 MODIFIKASI FUNGSI: Otomatis pindah scene saat selesai
func _on_heating_complete():
	print("🎉 SELAMAT! Tabung berhasil dipanaskan dengan Bunsen modern!")
	
	# 🔥 BARU: Simpan status selesai ke skrip Global Autoload
	Global.is_heating_completed = true
	
	# Memberikan jeda 1 detik agar animasi/efek selesai penuh kelihatan dulu
	await get_tree().create_timer(1.0).timeout
	
	if main_game_scene == "":
		print("ERROR: Path target scene untuk kembali kosong!")
		return
		
	# Proses kembali ke scene game utama
	var error_code = get_tree().change_scene_to_file(main_game_scene)
	if error_code != OK:
		print("ERROR: Gagal kembali ke scene utama. Kode Error: ", error_code)
