extends Control


# ==============================
# Tutorial
# ==============================

var tutorial_scene = preload("res://levels/minigames/destilasi/tutorial/UI_Tutorial.tscn")


# ==============================
# Export Variables (Inspector)
# ==============================

@export_file("*.tscn") var scene_tujuan: String = "" # Fallback scene tujuan jika scene asal kosong
@export var labu_sprite_changed: Texture2D
@export var waktu_proses: float = 20.0
@export var durasi_transisi: float = 1.0 # Jeda sebelum loading screen dimulai
@export var advance_story_to: GameState.StoryStage = GameState.StoryStage.POST_SHOWER

# ==============================
# Node
# ==============================

@onready var labu: TextureRect = $labu
@onready var erle: TextureRect = $erle
@onready var sulfur: TextureRect = $sulfur

@onready var llabu: Area2D = $Llabu
@onready var lerle: Area2D = $Lerle

@onready var plabu: Node2D = $Plabu
@onready var perle: Node2D = $Perle

@onready var progress_bar: ProgressBar = $Progressbar


# ==============================
# Variable
# ==============================

var gameplay_aktif := false

# Drag
var dragging_item: Control = null
var drag_offset: Vector2 = Vector2.ZERO

# Status
var sulfur_dropped: bool = false
var labu_locked: bool = false
var erle_locked: bool = false

var process_started: bool = false
var timer: float = 0.0

# Posisi Awal
var labu_initial_pos: Vector2 = Vector2.ZERO
var erle_initial_pos: Vector2 = Vector2.ZERO
var sulfur_initial_pos: Vector2 = Vector2.ZERO


# ==============================
# Ready
# ==============================

func _ready() -> void:
	# Pengaman: Jika minigame sudah selesai, pastikan spawn_point kosong lalu kembalikan player
	if "is_destilasi_completed" in Global and Global.is_destilasi_completed:
		print("Minigame ini sudah selesai! Mengembalikan player...")
		if "spawn_point" in Global:
			Global.spawn_point = ""
		pindah_ke_scene_tujuan()
		return

	print("================================")
	print("DESTILASI READY")
	print("================================")

	# Simpan posisi awal UI
	labu_initial_pos = labu.position
	erle_initial_pos = erle.position
	sulfur_initial_pos = sulfur.position

	# Progress bar
	progress_bar.value = 0.0
	progress_bar.visible = false

	# TextureRect menerima mouse
	labu.mouse_filter = Control.MOUSE_FILTER_STOP
	erle.mouse_filter = Control.MOUSE_FILTER_STOP
	sulfur.mouse_filter = Control.MOUSE_FILTER_STOP

	# Tampilkan tutorial saat scene dimuat
	tampilkan_tutorial()


# ==============================
# Tutorial
# ==============================

func tampilkan_tutorial() -> void:
	gameplay_aktif = false
	
	var tutorial = tutorial_scene.instantiate()
	add_child(tutorial)
	
	if tutorial is Control:
		tutorial.set_anchors_preset(Control.PRESET_FULL_RECT)
		
	tutorial.tutorial_selesai.connect(_on_tutorial_selesai)

func _on_tutorial_selesai() -> void:
	gameplay_aktif = true
	print("Gameplay Destilasi Dimulai")


# ==============================
# Process
# ==============================

func _process(delta: float) -> void:

	if not gameplay_aktif:
		return

	# --------------------------------------------------------
	# DRAG
	# --------------------------------------------------------

	if dragging_item != null:

		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):

			var mouse_position: Vector2 = get_global_mouse_position()

			dragging_item.global_position = (
				mouse_position + drag_offset
			)

		else:

			_drop_item()


	# --------------------------------------------------------
	# PROGRESS
	# --------------------------------------------------------

	if process_started:

		timer += delta

		var progress: float = (
			timer / waktu_proses
		) * 100.0

		if progress > 100.0:
			progress = 100.0

		progress_bar.value = progress

		if timer >= waktu_proses:

			process_started = false

			progress_bar.value = 100.0

			print("================================")
			print("DESTILASI SELESAI")
			print("================================")

			game_finished()


# ==============================
# Input Mouse
# ==============================

func _input(event: InputEvent) -> void:

	if not gameplay_aktif:
		return

	if not event is InputEventMouseButton:
		return

	var mouse_event: InputEventMouseButton = (
		event as InputEventMouseButton
	)

	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return


	if mouse_event.pressed:

		if dragging_item != null:
			return

		var mouse_position: Vector2 = (
			get_global_mouse_position()
		)

		var selected_item: Control = (
			_find_item_under_mouse(mouse_position)
		)

		if selected_item == null:
			return

		print("Klik pada: ", selected_item.name)

		if not _can_drag_item(selected_item):
			print("Tidak boleh di-drag: ", selected_item.name)
			return

		dragging_item = selected_item

		drag_offset = (
			selected_item.global_position
			- mouse_position
		)

		selected_item.z_index = 100

		print("================================")
		print("DRAG MULAI: ", selected_item.name)
		print("================================")

	else:

		if dragging_item != null:

			print("Mouse dilepas: ", dragging_item.name)

			_drop_item()


# ==============================
# Mencari Item di Bawah Mouse
# ==============================

func _find_item_under_mouse(
	mouse_position: Vector2
) -> Control:

	if sulfur.visible:

		var sulfur_rect: Rect2 = (
			sulfur.get_global_rect()
		)

		if sulfur_rect.has_point(mouse_position):

			return sulfur


	if labu.visible:

		var labu_rect: Rect2 = (
			labu.get_global_rect()
		)

		if labu_rect.has_point(mouse_position):

			return labu


	if erle.visible:

		var erle_rect: Rect2 = (
			erle.get_global_rect()
		)

		if erle_rect.has_point(mouse_position):

			return erle


	return null


# ==============================
# Cek Boleh Drag
# ==============================

func _can_drag_item(item: Control) -> bool:

	if item == sulfur:

		if sulfur_dropped:
			return false

		return true


	if item == labu:

		if not sulfur_dropped:
			return false

		if labu_locked:
			return false

		return true


	if item == erle:

		if not sulfur_dropped:
			return false

		if erle_locked:
			return false

		return true


	return false


# ==============================
# Drop Item
# ==============================

func _drop_item() -> void:

	var item: Control = dragging_item

	if item == null:
		return

	var mouse_position: Vector2 = (
		get_global_mouse_position()
	)

	item.z_index = 0


	if item == sulfur:

		print("Mencoba drop sulfur")

		if _is_mouse_inside_texture(
			mouse_position,
			labu
		):

			print("SULFUR -> LABU")

			_sulfur_dropped_to_labu()

		else:

			print("Sulfur tidak berada di labu")

			sulfur.position = sulfur_initial_pos


	elif item == labu:

		print("Mencoba drop labu")

		if _is_mouse_inside_area(
			mouse_position,
			llabu
		):

			print("LABU -> LLABU")

			_labu_dropped_to_llabu()

		else:

			print("Labu tidak berada di Llabu")

			labu.position = labu_initial_pos


	elif item == erle:

		print("Mencoba drop erle")

		if _is_mouse_inside_area(
			mouse_position,
			lerle
		):

			print("ERLE -> LERLE")

			_erle_dropped_to_lerle()

		else:

			print("Erle tidak berada di Lerle")

			erle.position = erle_initial_pos


	dragging_item = null


# ==============================
# Cek Mouse di TextureRect
# ==============================

func _is_mouse_inside_texture(
	mouse_position: Vector2,
	texture_rect: TextureRect
) -> bool:

	var rect: Rect2 = (
		texture_rect.get_global_rect()
	)

	return rect.has_point(mouse_position)


# ==============================
# Cek Mouse di Area2D
# ==============================

func _is_mouse_inside_area(
	mouse_position: Vector2,
	area: Area2D
) -> bool:

	var collision_node: Node = (
		area.get_node_or_null("CollisionShape2D")
	)

	if collision_node == null:

		print(
			"ERROR: CollisionShape2D tidak ditemukan pada ",
			area.name
		)

		return false


	var collision: CollisionShape2D = (
		collision_node as CollisionShape2D
	)

	if collision == null:

		print(
			"ERROR: Node CollisionShape2D tidak valid"
		)

		return false


	if collision.shape == null:

		print(
			"ERROR: CollisionShape2D tidak mempunyai Shape"
		)

		return false


	if collision.shape is RectangleShape2D:

		var rectangle_shape: RectangleShape2D = (
			collision.shape as RectangleShape2D
		)

		var local_mouse: Vector2 = (
			collision.to_local(mouse_position)
		)

		var rectangle: Rect2 = Rect2(
			-rectangle_shape.size / 2.0,
			rectangle_shape.size
		)

		return rectangle.has_point(local_mouse)


	if collision.shape is CircleShape2D:

		var circle_shape: CircleShape2D = (
			collision.shape as CircleShape2D
		)

		var local_mouse_circle: Vector2 = (
			collision.to_local(mouse_position)
		)

		return (
			local_mouse_circle.length()
			<= circle_shape.radius
		)


	print(
		"PERINGATAN: Shape tidak didukung pada ",
		area.name
	)

	return false


# ==============================
# Logika Drop
# ==============================

func _sulfur_dropped_to_labu() -> void:

	sulfur_dropped = true
	sulfur.visible = false

	if labu_sprite_changed != null:
		labu.texture = labu_sprite_changed
		print("Gambar labu berhasil berubah")
	else:
		print("PERINGATAN: labu_sprite_changed belum diisi")

	sulfur.position = sulfur_initial_pos


func _labu_dropped_to_llabu() -> void:

	labu_locked = true
	labu.global_position = plabu.global_position
	labu.mouse_filter = Control.MOUSE_FILTER_IGNORE

	print("LABU TERKUNCI")
	_check_all_locked()


func _erle_dropped_to_lerle() -> void:

	erle_locked = true
	erle.global_position = perle.global_position
	erle.mouse_filter = Control.MOUSE_FILTER_IGNORE

	print("ERLE TERKUNCI")
	_check_all_locked()


func _check_all_locked() -> void:

	if labu_locked and erle_locked:

		print("================================")
		print("SEMUA ALAT SUDAH TERPASANG")
		print("MEMULAI DESTILASI")
		print("================================")

		_start_progress()


func _start_progress() -> void:

	if process_started:
		return

	process_started = true
	timer = 0.0

	progress_bar.value = 0.0
	progress_bar.visible = true

	print("Progress dimulai: 0% -> 100%")


# ==============================
# Finish & Loading Screen Transisi
# ==============================

func game_finished() -> void:

	# KUNCI INPUT & STATUS GAMEPLAY
	gameplay_aktif = false
	process_started = false
	dragging_item = null

	# Matikan loop _process dan input handler
	set_process(false)
	set_process_input(false)

	print("🏆 MINIGAME DESTILASI SELESAI!")

	# Tandai status di Global Singleton
	if "is_destilasi_completed" in Global:
		Global.is_destilasi_completed = true

	# Pastikan spawn_point kosong agar player.gd mengembalikan posisi awal player_last_position
	if "spawn_point" in Global:
		Global.spawn_point = ""

	# Tunggu jeda efek sebelum pindah
	await get_tree().create_timer(durasi_transisi).timeout

	if GameState.current_stage < advance_story_to:
			GameState.current_stage = advance_story_to
			print("Progres cerita diperbarui ke: ", GameState.current_stage)

	pindah_ke_scene_tujuan()


func pindah_ke_scene_tujuan() -> void:

	var tujuan_final = ""

	# 1. Ambil scene asal player
	if "scene_asal_path" in Global and Global.scene_asal_path != "":
		tujuan_final = Global.scene_asal_path
	# 2. Fallback jika scene_asal_path kosong
	elif scene_tujuan != "":
		tujuan_final = scene_tujuan
	else:
		print("PERINGATAN: Tidak ada scene tujuan yang terdeteksi!")
		return

	print("🔄 Memulangkan player ke: ", tujuan_final)

	# Pindah scene lewat TransitionScreen Autoload
	if has_node("/root/TransitionScreen"):
		TransitionScreen.transition_to_scene(tujuan_final)
	else:
		get_tree().change_scene_to_file(tujuan_final)


# ==============================
# Reset Game
# ==============================

func reset_game() -> void:

	print("RESET DESTILASI")

	set_process(true)
	set_process_input(true)

	sulfur_dropped = false
	labu_locked = false
	erle_locked = false
	process_started = false

	timer = 0.0
	dragging_item = null
	drag_offset = Vector2.ZERO

	progress_bar.value = 0.0
	progress_bar.visible = false

	labu.position = labu_initial_pos
	erle.position = erle_initial_pos
	sulfur.position = sulfur_initial_pos

	sulfur.visible = true

	labu.mouse_filter = Control.MOUSE_FILTER_STOP
	erle.mouse_filter = Control.MOUSE_FILTER_STOP	
	sulfur.mouse_filter = Control.MOUSE_FILTER_STOP

	tampilkan_tutorial()
