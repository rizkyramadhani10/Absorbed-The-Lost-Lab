extends Node2D

@onready var rak_tabung = $"Tabung Ambil"
@onready var tabung_tunggal = $"Tabung Reaksi"
@onready var pencapit = $Pencapit # TAMBAHAN: Ambil referensi ke script Pencapit

# PERBAIKAN: Jalur file disesuaikan dengan folder ASSETS
var tekstur_rak_baru = preload("res://assets/images/itemProps/interactableProps/bunsen/t_sdh_ambil.png")

func _ready():
	# Sembunyikan tabung reaksi tunggal saat game baru mulai
	tabung_tunggal.visible = false
	
	# Hubungkan fungsi klik ke Area2D milik Rak (Tabung Ambil)
	rak_tabung.input_event.connect(_on_rak_tabung_input_event)

func _on_rak_tabung_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	# Mendeteksi Klik Mouse (PC) atau Tap Layar (Mobile)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			eksekusi_ambil_tabung()

func eksekusi_ambil_tabung():
	# --- FIX DI SINI: KUNCI ANTI-DUPLIKAT ---
	# 1. Jika tabung_tunggal masih eksis di meja (visible == true)
	# 2. ATAU jika pencapit lagi sibuk megang tabung (pencapit.is_holding_tube == true)
	# Maka batalkan (return) proses kemunculan tabung baru.
	if tabung_tunggal.visible or pencapit.is_holding_tube:
		return
		
	# 1. Munculkan tabung tunggal yang di samping
	tabung_tunggal.visible = true
	
	# 2. Ganti gambar di dalam Sprite2D milik rak menjadi t_sdh_ambil.png
	rak_tabung.get_node("Sprite2D").texture = tekstur_rak_baru
