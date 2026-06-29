extends Control

# Preload file scene tutorial agar siap dipanggil kapan saja
var tutorial_scene = preload("res://levels/minigames/klasifikasiLimbah/Tutorial/UI_Tutorial.tscn") # <-- Sesuaikan path ini dengan letak file .tscn tutorialmu

@onready var tumpukan_limbah_node = $HoldingArea_Limbah # Mengikuti nama node terbaru di scene treemu
@onready var label_timer = $HUD_Timer
@onready var wadah_intake = $WadahIntake

# NODE AUDIO
@onready var bgm_player = $BGMPlayer
@onready var sfx_win = $SFXWin
@onready var sfx_timer_warning = $SFXTimerWarning

@export var batas_waktu: float = 60.0
var waktu_aktif: bool = false # Wajib false agar timer membeku saat tutorial muncul
var alarm_dipicu: bool = false

var daftar_limbah: Array = [
	{"nama": "Limbah radioaktif cair", "wujud": "cair", "simbol": "beracun", "texture": preload("res://levels/minigames/klasifikasiLimbah/itemLimbah/spriteLimbah/cairBeracun3.png")},
	{"nama": "Asam Sulfat", "wujud": "cair", "simbol": "beracun", "texture": preload("res://levels/minigames/klasifikasiLimbah/itemLimbah/spriteLimbah/cairBeracun.png")},
	{"nama": "Etanol bekas", "wujud": "cair", "simbol": "beracun", "texture": preload("res://levels/minigames/klasifikasiLimbah/itemLimbah/spriteLimbah/cairBeracun5.png")},
	{"nama": "Larutan Merkuri (Hg²⁺) bekas", "wujud": "cair", "simbol": "beracun", "texture": preload("res://levels/minigames/klasifikasiLimbah/itemLimbah/spriteLimbah/cairBeracun4.png")},
	{"nama": "Natrium Sianida (NaCN) bekas", "wujud": "cair", "simbol": "beracun", "texture": preload("res://levels/minigames/klasifikasiLimbah/itemLimbah/spriteLimbah/cairBeracun2.png")},
	
	{"nama": "Limbah biologis", "wujud": "padat", "simbol": "infeksius", "texture": preload("res://levels/minigames/klasifikasiLimbah/itemLimbah/spriteLimbah/padatInfeksius.png")},
	{"nama": "Adsorben/kertas saring terkontaminasi bahan kimia", "wujud": "padat", "simbol": "infeksius", "texture": preload("res://levels/minigames/klasifikasiLimbah/itemLimbah/spriteLimbah/padatInfeksius2.png")},
	{"nama": "Limbah radioaktif padat", "wujud": "padat", "simbol": "infeksius", "texture": preload("res://levels/minigames/klasifikasiLimbah/itemLimbah/spriteLimbah/padatInfeksius3.png")},
	{"nama": "Sarung tangan terkontaminasi", "wujud": "padat", "simbol": "infeksius", "texture": preload("res://levels/minigames/klasifikasiLimbah/itemLimbah/spriteLimbah/padatInfeksius4.png")}
]

func _ready() -> void:
	assign_data_ke_node_limbah()
	
	# MEMICU TUTORIAL MUNCUL INSTAN SAAT SCENE MASUK LOADING SCREEN / DI-RUN
	munculkan_tutorial_langsung()

func munculkan_tutorial_langsung() -> void:
	waktu_aktif = false # Kunci pergerakan waktu minigame
	
	# Cetak fisik scene tutorial dari memori
	var tutorial_instance = tutorial_scene.instantiate()
	
	# Masukkan ke dalam hierarchy scene utama agar muncul di layar paling depan
	add_child(tutorial_instance)
	
	# Hubungkan sinyal dari anak tutorial ke skrip utama ini secara dinamis
	tutorial_instance.tutorial_selesai.connect(_on_tutorial_game_dimulai)

# Fungsi tangkapan ketika pemain memencet tombol MULAI / SILANG di tablet tutorial
func _on_tutorial_game_dimulai() -> void:
	print("Tombol dipencet! Tutorial menghilang, minigame dimulai!")
	
	# Aktifkan jalannya timer game dan putar BGM laboratorium
	waktu_aktif = true
	if bgm_player and not bgm_player.playing:
		bgm_player.play()

func _process(delta: float) -> void:
	if waktu_aktif:
		batas_waktu -= delta
		label_timer.text = "SISA WAKTU: " + str(int(batas_waktu)) + "s"
		
		if batas_waktu <= 10.0 and not alarm_dipicu:
			alarm_dipicu = true
			if sfx_timer_warning: sfx_timer_warning.play()
		
		if batas_waktu <= 0:
			waktu_aktif = false
			eksekusi_game_over()

func assign_data_ke_node_limbah():
	var semua_node_limbah = tumpukan_limbah_node.get_children()
	var jumlah_item = min(daftar_limbah.size(), semua_node_limbah.size())
	for i in range(jumlah_item):
		var data = daftar_limbah[i]
		var node_limbah = semua_node_limbah[i]
		node_limbah.nama_item = data["nama"]
		node_limbah.wujud_limbah = data["wujud"]
		node_limbah.simbol_k3 = data["simbol"]
		node_limbah.texture = data["texture"]
		node_limbah.visible = true

func cek_apakah_baki_limbah_habis() -> bool:
	for limbah in tumpukan_limbah_node.get_children():
		if limbah.visible:
			return false
	return true

func kurangi_hp(jumlah: int):
	print("HP Berkurang: ", jumlah)

# Di dalam script: minigame_limbah.gd

func pemicu_menang():
	waktu_aktif = false
	if bgm_player: bgm_player.stop()
	if sfx_timer_warning: sfx_timer_warning.stop()
	
	if sfx_win: 
		sfx_win.play()
	
	print("MENANG! Mensterilkan ruangan...")
	
	# 1. Tandai di Global kalau minigame ini sudah sukses dikerjakan
	Global.limbah_minigame_completed = true
	
	# 2. Beri jeda sejenak (misal 2 detik) agar pemain bisa mendengar SFX Win sampai habis
	await get_tree().create_timer(2.0).timeout
	
	# 3. Pulangkan player ke map asal yang sudah dicatat tadi
	if Global.scene_asal_path != "":
		print("Memulangkan Xeno ke: ", Global.scene_asal_path)
		get_tree().change_scene_to_file(Global.scene_asal_path)
	else:
		# Antisipasi jika semisal kamu me-run langsung scene minigame ini dari editor (tanpa lewat map)
		print("Peringatan: Scene asal tidak tercatat! Membuka fallback map...")
		get_tree().change_scene_to_file("res://levels/secondLab/game.tscn") # <-- Ganti dengan path map utamamu

func eksekusi_game_over():
	if sfx_timer_warning: sfx_timer_warning.stop()
	if bgm_player: bgm_player.stop()
	if wadah_intake and wadah_intake.has_node("SFXStickerWrong"):
		wadah_intake.get_node("SFXStickerWrong").play()
	print("GAME OVER!")
