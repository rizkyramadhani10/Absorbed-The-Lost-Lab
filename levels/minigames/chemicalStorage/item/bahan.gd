extends Area2D

signal item_pressed(item)
signal item_dropped(item)

# ==============================
# EXPORT VARIABLES - Bisa diatur dari Inspector
# ==============================

@export var chemical_id: String = ""  # ID dari database
@export var chemical_name: String = "Bahan Kimia"
@export var chemical_category: String = ""
@export var chemical_properties: String = ""
@export var chemical_texture: Texture2D  # Gambar bisa diisi dari inspector

# ==============================
# INTERNAL VARIABLES
# ==============================

var chemical_data: Dictionary = {}

var dragging := false
var placed := false

var finger_index := -1

var drag_offset := Vector2.ZERO
var start_position := Vector2.ZERO

# ==============================
# NODE REFERENCES
# ==============================

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


# ==============================
# READY
# ==============================

func _ready() -> void:
	start_position = global_position
	
	# Jika ada texture dari inspector, langsung tampilkan
	if chemical_texture:
		sprite.texture = chemical_texture
	
	# Jika ada data dari database, gunakan itu
	if chemical_id != "":
		load_from_database(chemical_id)


# ==============================
# DATABASE FUNCTIONS
# ==============================

func load_from_database(id: String) -> void:
	"""Memuat data dari database berdasarkan ID"""
	var db = preload("res://levels/minigames/chemicalStorage/data/chemical_database.gd")
	var chemicals = db.CHEMICALS
	
	for chem in chemicals:
		if chem["id"] == id:
			set_data(chem)
			return
	
	print("⚠️ Bahan dengan ID '", id, "' tidak ditemukan di database!")


func set_data(data: Dictionary) -> void:
	"""Mengatur data bahan dari dictionary"""
	chemical_data = data
	
	if data.has("nama"):
		chemical_name = data["nama"]
	
	if data.has("kategori"):
		chemical_category = data["kategori"]
	
	if data.has("sifat"):
		chemical_properties = data["sifat"]
	
	if data.has("gambar") and data["gambar"] != null:
		sprite.texture = data["gambar"]
		chemical_texture = data["gambar"]
	
	if data.has("id"):
		chemical_id = data["id"]


# ==============================
# INPUT HANDLING
# ==============================

func _input(event):
	if placed:
		return
	
	# =============================
	# ANDROID (Touch)
	# =============================
	if event is InputEventScreenTouch:
		if event.pressed:
			# Cek apakah touch berada di dalam sprite
			if is_point_inside_sprite(event.position):
				dragging = true
				finger_index = event.index
				drag_offset = global_position - event.position
				item_pressed.emit(self)
		else:
			if dragging and finger_index == event.index:
				dragging = false
				finger_index = -1
				item_dropped.emit(self)
				get_parent().get_parent().get_parent().drop_item(self)
	
	# =============================
	# EDITOR / PC (Mouse)
	# =============================
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Cek apakah mouse berada di dalam sprite
				if is_point_inside_sprite(event.position):
					dragging = true
					drag_offset = global_position - get_global_mouse_position()
					item_pressed.emit(self)
			else:
				if dragging:
					dragging = false
					item_dropped.emit(self)
					get_parent().get_parent().drop_item(self)


# ==============================
# HELPER FUNCTIONS
# ==============================

func is_point_inside_sprite(point: Vector2) -> bool:
	"""Cek apakah point berada di dalam area sprite"""
	# Konversi point ke koordinat lokal Area2D
	var local_point = to_local(point)
	
	# Cek apakah point berada di dalam area sprite
	if sprite and sprite.texture:
		var rect = sprite.get_rect()
		return rect.has_point(local_point)
	
	# Fallback: cek dengan collision shape
	if collision_shape and collision_shape.shape:
		var shape = collision_shape.shape
		if shape is RectangleShape2D:
			var rect = Rect2(
				-collision_shape.position - shape.size / 2,
				shape.size
			)
			return rect.has_point(local_point)
	
	return false


# ==============================
# PROCESS
# ==============================

func _process(delta):
	if placed:
		return
	
	if dragging:
		if DisplayServer.is_touchscreen_available():
			# Android
			var mouse_pos = get_viewport().get_mouse_position()
			global_position = mouse_pos + drag_offset
		else:
			# Windows/Linux/Mac Editor
			global_position = get_global_mouse_position() + drag_offset


# ==============================
# PUBLIC FUNCTIONS
# ==============================

func return_to_origin() -> void:
	"""Kembalikan bahan ke posisi awal"""
	global_position = start_position
	placed = false
	dragging = false
	collision_shape.disabled = false


func place_to(pos: Vector2) -> void:
	"""Tempatkan bahan di posisi tertentu"""
	global_position = pos
	placed = true
	dragging = false
	# Nonaktifkan collision agar tidak bisa di-drag lagi
	collision_shape.disabled = true


func get_chemical_info() -> Dictionary:
	"""Mendapatkan informasi bahan dalam bentuk dictionary"""
	return {
		"id": chemical_id,
		"nama": chemical_name,
		"kategori": chemical_category,
		"sifat": chemical_properties
	}
