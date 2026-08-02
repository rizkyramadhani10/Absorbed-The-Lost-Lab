extends Control

# ==============================
# Tutorial
# ==============================

var tutorial_scene = preload("res://levels/minigames/chemicalStorage/tutorial/UI_Tutorial.tscn")

# ==============================
# Database
# ==============================

const ChemicalDatabase = preload("res://levels/minigames/chemicalStorage/data/chemical_database.gd")

# ==============================
# Node
# ==============================

@onready var bahan_container = $ChemContainer/Bahan
@onready var rack = $Rack

@onready var panel = $Panel
@onready var label_nama = $Panel/Nama
@onready var label_kategori = $Panel/Kategori
@onready var label_sifat = $Panel/Sifat

# ==============================
# Audio Nodes (Opsional)
# ==============================

#@onready var bgm_player = $BGMPlayer  # Tambahkan AudioStreamPlayer untuk BGM
#@onready var sfx_win = $SFXWin      # Tambahkan AudioStreamPlayer untuk SFX menang
#@onready var sfx_placed = $SFXPlaced # Tambahkan AudioStreamPlayer untuk SFX menaruh bahan

# ==============================
# Export Variables - Bisa diatur di Inspector!
# ==============================

@export var scene_tujuan: String = "res://levels/storage/game.tscn"  # Path ke scene gudang
@export var durasi_transisi: float = 2.0  # Durasi jeda sebelum pindah scene

# ==============================
# Variable
# ==============================

var gameplay_aktif := false
var current_item = null
var item_placed_count := 0  # Counter untuk bahan yang sudah ditempatkan

# ==============================
# Ready
# ==============================

func _ready():
	panel.visible = false
	setup_items()
	tampilkan_tutorial()
	
	# Putar BGM jika ada
	#if bgm_player and not bgm_player.playing:
		#bgm_player.play()

# ==============================
# Setup Item
# ==============================

func setup_items():
	var daftar = ChemicalDatabase.CHEMICALS
	var semua_item = bahan_container.get_children()
	
	for i in range(min(daftar.size(), semua_item.size())):
		var item = semua_item[i]
		item.set_data(daftar[i])
		item.item_pressed.connect(_on_item_pressed)

# ==============================
# Klik Item
# ==============================

func _on_item_pressed(item):
	if !gameplay_aktif:
		return
	
	current_item = item
	panel.visible = true
	
	label_nama.text = item.chemical_data["nama"]
	label_kategori.text = "Kategori : " + item.chemical_data["kategori"]
	label_sifat.text = item.chemical_data["sifat"]

# ==============================
# Tutorial
# ==============================

func tampilkan_tutorial():
	gameplay_aktif = false
	
	# Hentikan BGM saat tutorial (opsional)
	#if bgm_player and bgm_player.playing:
		#bgm_player.stop()
	
	var tutorial = tutorial_scene.instantiate()
	add_child(tutorial)
	tutorial.tutorial_selesai.connect(_on_tutorial_selesai)

func _on_tutorial_selesai():
	gameplay_aktif = true
	print("Gameplay dimulai")
	
	# Putar BGM setelah tutorial selesai
	#if bgm_player and not bgm_player.playing:
		#bgm_player.play()

# ==============================
# Drop Item - DIPERBAIKI
# ==============================

func drop_item(item):
	if !gameplay_aktif:
		return
	
	# Cari slot berdasarkan posisi item
	var slot = get_slot(item.global_position)
	
	if slot == null:
		print("❌ Tidak menemukan slot")
		item.return_to_origin()
		return
	
	print("✅ Slot ditemukan: ", slot.name)
	print("   Kategori slot: ", slot.category)
	print("   Kategori item: ", item.chemical_data["kategori"])
	
	# Cek kecocokan kategori
	if slot.category == item.chemical_data["kategori"]:
		print("✅ BENAR - Kategori cocok!")
		
		# Place item ke snap point
		if slot.has_node("SnapPoint"):
			var snap_point = slot.get_node("SnapPoint")
			item.place_to(snap_point.global_position)
			
			# Putar SFX placed (jika ada)
			#if sfx_placed:
				#sfx_placed.play()
			
			# Update counter
			item_placed_count += 1
			
			check_win()
		else:
			print("⚠️ SnapPoint tidak ditemukan di slot: ", slot.name)
			item.return_to_origin()
	else:
		print("❌ SALAH - Kategori tidak cocok!")
		item.return_to_origin()

# ==============================
# Cari Slot - DIPERBAIKI
# ==============================

func get_slot(pos):
	# Cek semua Area2D di dalam Rack
	for child in rack.get_children():
		if child is Area2D:
			# Cek apakah posisi berada di dalam collision shape
			if child.has_method("is_point_inside"):
				if child.is_point_inside(pos):
					print("🎯 Point masuk ke slot: ", child.name)
					return child
			else:
				# Fallback: cek dengan get_rect jika method tidak ada
				if child.has_method("get_rect"):
					if child.get_rect().has_point(pos):
						print("🎯 Point masuk ke slot (fallback): ", child.name)
						return child
	return null

# ==============================
# Check Win - DIPERBAIKI
# ==============================

func check_win():
	# Cek apakah semua bahan sudah ditempatkan
	var total_bahan = bahan_container.get_children().size()
	
	if item_placed_count >= total_bahan:
		print("🎉 SEMUA BAHAN SUDAH TERSIMPAN!")
		game_finished()
	else:
		print("📦 Bahan tersimpan: ", item_placed_count, "/", total_bahan)

# ==============================
# Finish - DIPERBAIKI
# ==============================

func game_finished():
	gameplay_aktif = false
	
	# Hentikan BGM
	#if bgm_player and bgm_player.playing:
		#bgm_player.stop()
	
	# Putar SFX menang (jika ada)
	#if sfx_win:
		#sfx_win.play()
	
	print("🏆 MINIGAME SELESAI!")
	print("   Total bahan tersimpan: ", item_placed_count)
	
	# Tandai di Global kalau minigame ini sudah selesai
	Global.minigame_penataan_completed = true
	
	GameState.advance_to(GameState.StoryStage.MANAGE_STORAGE)
	
	# Tunggu sebentar agar pemain bisa mendengar SFX
	await get_tree().create_timer(durasi_transisi).timeout
	
	# Kembali ke scene tujuan
	pindah_ke_scene_tujuan()

# ==============================
# Pindah ke Scene Tujuan - BARU
# ==============================

func pindah_ke_scene_tujuan():
	print("🔄 Memindahkan ke scene: ", scene_tujuan)
	
	# Cek apakah ada TransitionScreen
	if has_node("/root/TransitionScreen"):
		# Jika ada, gunakan transisi halus
		TransitionScreen.transition_to_scene(scene_tujuan)
	else:
		# Jika tidak, langsung pindah
		get_tree().change_scene_to_file(scene_tujuan)

# ==============================
# Reset Game (Opsional)
# ==============================

func reset_game():
	# Reset semua item ke posisi awal
	for item in bahan_container.get_children():
		item.return_to_origin()
		item.placed = false
		item.collision_shape.disabled = false
	
	item_placed_count = 0
	gameplay_aktif = true
	panel.visible = false
	
	print("🔄 Game di-reset!")
