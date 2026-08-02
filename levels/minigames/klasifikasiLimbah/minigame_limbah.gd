extends Control

var tutorial_scene = preload("res://levels/minigames/klasifikasiLimbah/Tutorial/UI_Tutorial.tscn")

@onready var tumpukan_limbah_node = $GameBoard/HoldingArea_Limbah
@onready var label_timer = $GameBoard/HUD_Timer
@onready var wadah_intake = $GameBoard/WadahIntake
@export var advance_story_to: GameState.StoryStage = GameState.StoryStage.POST_SHOWER

# NODE AUDIO
@onready var bgm_player = $GameBoard/BGMPlayer
@onready var sfx_win = $GameBoard/SFXWin
@onready var sfx_timer_warning = $GameBoard/SFXTimerWarning

@export var batas_waktu: float = 60.0
var waktu_aktif: bool = false
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
	munculkan_tutorial_langsung()

func munculkan_tutorial_langsung() -> void:
	waktu_aktif = false
	var tutorial_instance = tutorial_scene.instantiate()
	add_child(tutorial_instance)
	tutorial_instance.tutorial_selesai.connect(_on_tutorial_game_dimulai)

func _on_tutorial_game_dimulai() -> void:
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
		if limbah.visible and not limbah.is_queued_for_deletion():
			return false
	return true

# 🔥 FUNGSI STICKER DAN LOGIKA KEMENANGAN BALIK LAGI
func pemicu_menang():
	waktu_aktif = false
	if bgm_player: bgm_player.stop()
	if sfx_timer_warning: sfx_timer_warning.stop()
	if sfx_win: sfx_win.play()
	
	print("MENANG! Mensterilkan ruangan...")
	Global.limbah_minigame_completed = true
	
	await get_tree().create_timer(2.0).timeout
	pindah_ke_scene_tujuan()

func pindah_ke_scene_tujuan():
	var tujuan_final = Global.scene_asal_path if Global.scene_asal_path != "" else "res://levels/secondLab/game.tscn"
	if has_node("/root/TransitionScreen"):
		TransitionScreen.transition_to_scene(tujuan_final)# Cek variabel secara dinamis
		
		# 🔥 Tunda 1 frame agar Node lain (seperti LevelManager) selesai _ready()
		await get_tree().process_frame
		
		# 🔥 Majukan progres cerita jika belum mencapai target stage
		if GameState.current_stage < advance_story_to:
			GameState.current_stage = advance_story_to
			print("Progres cerita diperbarui ke: ", GameState.current_stage)
			
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = true
		return 
	else:
		get_tree().change_scene_to_file(tujuan_final)

func eksekusi_game_over():
	if sfx_timer_warning: sfx_timer_warning.stop()
	if bgm_player: bgm_player.stop()
	if wadah_intake and wadah_intake.has_node("SFXStickerWrong"):
		wadah_intake.get_node("SFXStickerWrong").play()
	print("GAME OVER!")

func kurangi_hp(jumlah: int):
	print("HP Berkurang: ", jumlah)
