extends Control


# ============================================================
# INSPECTOR
# ============================================================

@export_file("*.tscn") var next_scene: String = ""
@export var labu_sprite_changed: Texture2D
@export var waktu_proses: float = 20.0


# ============================================================
# NODE
# ============================================================

@onready var labu: TextureRect = $labu
@onready var erle: TextureRect = $erle
@onready var sulfur: TextureRect = $sulfur

@onready var llabu: Area2D = $Llabu
@onready var lerle: Area2D = $Lerle

@onready var plabu: Node2D = $Plabu
@onready var perle: Node2D = $Perle

@onready var progress_bar: ProgressBar = $Progressbar


# ============================================================
# DRAG
# ============================================================

var dragging_item: Control = null
var drag_offset: Vector2 = Vector2.ZERO


# ============================================================
# STATUS
# ============================================================

var sulfur_dropped: bool = false
var labu_locked: bool = false
var erle_locked: bool = false

var process_started: bool = false
var timer: float = 0.0


# ============================================================
# POSISI AWAL
# ============================================================

var labu_initial_pos: Vector2 = Vector2.ZERO
var erle_initial_pos: Vector2 = Vector2.ZERO
var sulfur_initial_pos: Vector2 = Vector2.ZERO


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	print("================================")
	print("DESTILASI READY")
	print("================================")

	# Simpan posisi awal
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

	print("Labu : ", labu.name)
	print("Erle  : ", erle.name)
	print("Sulfur: ", sulfur.name)

	print("Ukuran Labu   : ", labu.size)
	print("Ukuran Erle   : ", erle.size)
	print("Ukuran Sulfur : ", sulfur.size)


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:

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

			_change_to_next_scene()


# ============================================================
# INPUT MOUSE
# ============================================================

func _input(event: InputEvent) -> void:

	if not event is InputEventMouseButton:
		return

	var mouse_event: InputEventMouseButton = (
		event as InputEventMouseButton
	)

	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return


	# --------------------------------------------------------
	# MOUSE DITEKAN
	# --------------------------------------------------------

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

		# Mulai drag
		dragging_item = selected_item

		drag_offset = (
			selected_item.global_position
			- mouse_position
		)

		selected_item.z_index = 100

		print("================================")
		print("DRAG MULAI: ", selected_item.name)
		print("================================")


	# --------------------------------------------------------
	# MOUSE DILEPAS
	# --------------------------------------------------------

	else:

		if dragging_item != null:

			print("Mouse dilepas: ", dragging_item.name)

			_drop_item()


# ============================================================
# MENCARI ITEM DI BAWAH MOUSE
# ============================================================

func _find_item_under_mouse(
	mouse_position: Vector2
) -> Control:

	# Sulfur
	if sulfur.visible:

		var sulfur_rect: Rect2 = (
			sulfur.get_global_rect()
		)

		if sulfur_rect.has_point(mouse_position):

			return sulfur


	# Labu
	if labu.visible:

		var labu_rect: Rect2 = (
			labu.get_global_rect()
		)

		if labu_rect.has_point(mouse_position):

			return labu


	# Erle
	if erle.visible:

		var erle_rect: Rect2 = (
			erle.get_global_rect()
		)

		if erle_rect.has_point(mouse_position):

			return erle


	return null


# ============================================================
# CEK BOLEH DRAG
# ============================================================

func _can_drag_item(item: Control) -> bool:

	# --------------------------------------------------------
	# SULFUR
	# --------------------------------------------------------

	if item == sulfur:

		if sulfur_dropped:
			return false

		return true


	# --------------------------------------------------------
	# LABU
	# --------------------------------------------------------

	if item == labu:

		if not sulfur_dropped:
			return false

		if labu_locked:
			return false

		return true


	# --------------------------------------------------------
	# ERLE
	# --------------------------------------------------------

	if item == erle:

		if not sulfur_dropped:
			return false

		if erle_locked:
			return false

		return true


	return false


# ============================================================
# DROP ITEM
# ============================================================

func _drop_item() -> void:

	var item: Control = dragging_item

	if item == null:
		return

	var mouse_position: Vector2 = (
		get_global_mouse_position()
	)

	item.z_index = 0


	# --------------------------------------------------------
	# SULFUR
	# --------------------------------------------------------

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


	# --------------------------------------------------------
	# LABU
	# --------------------------------------------------------

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


	# --------------------------------------------------------
	# ERLE
	# --------------------------------------------------------

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


# ============================================================
# CEK MOUSE DI TEXTURE RECT
# ============================================================

func _is_mouse_inside_texture(
	mouse_position: Vector2,
	texture_rect: TextureRect
) -> bool:

	var rect: Rect2 = (
		texture_rect.get_global_rect()
	)

	return rect.has_point(mouse_position)


# ============================================================
# CEK MOUSE DI AREA2D
# ============================================================

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


	# --------------------------------------------------------
	# RECTANGLE
	# --------------------------------------------------------

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


	# --------------------------------------------------------
	# CIRCLE
	# --------------------------------------------------------

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


# ============================================================
# SULFUR MASUK LABU
# ============================================================

func _sulfur_dropped_to_labu() -> void:

	sulfur_dropped = true

	# Hilangkan sulfur
	sulfur.visible = false

	# Ganti gambar labu
	if labu_sprite_changed != null:

		labu.texture = labu_sprite_changed

		print("Gambar labu berhasil berubah")

	else:

		print(
			"PERINGATAN: labu_sprite_changed belum diisi"
		)

	# Kembalikan sulfur ke posisi awal
	sulfur.position = sulfur_initial_pos


# ============================================================
# LABU MASUK LLABU
# ============================================================

func _labu_dropped_to_llabu() -> void:

	labu_locked = true

	# Snap ke Plabu
	labu.global_position = (
		plabu.global_position
	)

	# Tidak bisa di-drag lagi
	labu.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	print("LABU TERKUNCI")


	_check_all_locked()


# ============================================================
# ERLE MASUK LERLE
# ============================================================

func _erle_dropped_to_lerle() -> void:

	erle_locked = true

	# Snap ke Perle
	erle.global_position = (
		perle.global_position
	)

	# Tidak bisa di-drag lagi
	erle.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	print("ERLE TERKUNCI")


	_check_all_locked()


# ============================================================
# CEK SEMUA TERPASANG
# ============================================================

func _check_all_locked() -> void:

	if labu_locked and erle_locked:

		print("================================")
		print("SEMUA ALAT SUDAH TERPASANG")
		print("MEMULAI DESTILASI")
		print("================================")

		_start_progress()


# ============================================================
# MULAI PROGRESS BAR
# ============================================================

func _start_progress() -> void:

	if process_started:
		return

	process_started = true

	timer = 0.0

	progress_bar.value = 0.0
	progress_bar.visible = true

	print("Progress dimulai: 0% -> 100%")


# ============================================================
# PINDAH SCENE
# ============================================================

func _change_to_next_scene() -> void:

	if next_scene == "":

		print(
			"PERINGATAN: next_scene belum diisi!"
		)

		return


	print(
		"Pindah ke scene: ",
		next_scene
	)

	get_tree().change_scene_to_file(
		next_scene
	)


# ============================================================
# RESET GAME
# ============================================================

func reset_game() -> void:

	print("RESET DESTILASI")


	# Status
	sulfur_dropped = false
	labu_locked = false
	erle_locked = false

	process_started = false

	timer = 0.0

	dragging_item = null

	drag_offset = Vector2.ZERO


	# Progress
	progress_bar.value = 0.0
	progress_bar.visible = false


	# Posisi
	labu.position = labu_initial_pos
	erle.position = erle_initial_pos
	sulfur.position = sulfur_initial_pos


	# Sulfur muncul
	sulfur.visible = true


	# Aktifkan input
	labu.mouse_filter = Control.MOUSE_FILTER_STOP
	erle.mouse_filter = Control.MOUSE_FILTER_STOP
	sulfur.mouse_filter = Control.MOUSE_FILTER_STOP

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				print("========== KLIK MOUSE TERDETEKSI ==========")
				print("Posisi mouse: ", get_global_mouse_position())
				
				var rect: Rect2 = sulfur.get_global_rect()
				print("Rect sulfur: ", rect)
				
				print("Ukuran sulfur: ", sulfur.size)
				print("Posisi sulfur: ", sulfur.global_position)
				
				if rect.has_point(get_global_mouse_position()):
					print(">>> MOUSE BERADA DI SULFUR <<<")
				else:
					print(">>> MOUSE TIDAK BERADA DI SULFUR <<<")
