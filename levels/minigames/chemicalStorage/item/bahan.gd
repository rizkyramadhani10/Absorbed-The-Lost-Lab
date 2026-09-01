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
	
	if chemical_texture:
		sprite.texture = chemical_texture
	
	if chemical_id != "":
		load_from_database(chemical_id)


# ==============================
# DATABASE FUNCTIONS
# ==============================

func load_from_database(id: String) -> void:
	var db = preload("res://levels/minigames/chemicalStorage/data/chemical_database.gd")
	var chemicals = db.CHEMICALS
	
	for chem in chemicals:
		if chem["id"] == id:
			set_data(chem)
			return
	
	print("⚠️ Bahan dengan ID '", id, "' tidak ditemukan di database!")


func set_data(data: Dictionary) -> void:
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
# INPUT HANDLING (UNIFIED PC & MOBILE)
# ==============================

func _input(event):
	if placed:
		return
	
	# 📱 ANDROID / TOUCHSCREEN
	if event is InputEventScreenTouch:
		if event.pressed:
			if not dragging and is_point_inside_sprite(event.position):
				dragging = true
				finger_index = event.index
				# Gunakan get_global_mouse_position() atau konversi posisi touch ke canvas transform
				drag_offset = global_position - get_global_mouse_position()
				item_pressed.emit(self)
		else:
			if dragging and finger_index == event.index:
				dragging = false
				finger_index = -1
				item_dropped.emit(self)
				_trigger_drop()

	# 💻 PC / MOUSE
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if not dragging and is_point_inside_sprite(event.global_position):
					dragging = true
					drag_offset = global_position - get_global_mouse_position()
					item_pressed.emit(self)
			else:
				if dragging:
					dragging = false
					item_dropped.emit(self)
					_trigger_drop()

	# 🖱️ MOUSE MOTION / SCREEN DRAG (Agar botol mengikuti jari/mouse dengan akurat)
	elif dragging:
		if event is InputEventMouseMotion or event is InputEventScreenDrag:
			if finger_index == -1 or (event is InputEventScreenDrag and event.index == finger_index):
				global_position = get_global_mouse_position() + drag_offset


# ==============================
# HELPER FUNCTIONS
# ==============================

func is_point_inside_sprite(screen_point: Vector2) -> bool:
	"""Cek apakah titik sentuh/klik berada di dalam area sprite (Kompatibel Screen & Global)"""
	if sprite and sprite.texture:
		var global_rect = get_sprite_global_rect()
		return global_rect.has_point(screen_point)
	
	if collision_shape and collision_shape.shape:
		var shape = collision_shape.shape
		if shape is RectangleShape2D:
			var rect = Rect2(collision_shape.global_position - shape.size / 2, shape.size)
			return rect.has_point(screen_point)
			
	return false

func get_sprite_global_rect() -> Rect2:
	if not sprite or not sprite.texture:
		return Rect2()
	var texture_size = sprite.texture.get_size() * sprite.scale
	var top_left = sprite.global_position - (texture_size / 2.0)
	return Rect2(top_left, texture_size)


# ==============================
# PROCESS (FALLBACK POSISI)
# ==============================

func _process(_delta):
	if placed:
		return
	
	if dragging:
		# Pastikan posisi terus mengunci ke kursor/jari secara real-time
		global_position = get_global_mouse_position() + drag_offset


# ==============================
# SAFE DROP TRIGGER
# ==============================

func _trigger_drop() -> void:
	"""Mencari script utama mini-game secara aman tanpa bergantung struktur parent"""
	var main_game = get_tree().current_scene
	# Cari node root yang memiliki method drop_item
	if main_game.has_method("drop_item"):
		main_game.drop_item(self)
	else:
		# Fallback mencari ke atas
		var p = get_parent()
		while p:
			if p.has_method("drop_item"):
				p.drop_item(self)
				return
			p = p.get_parent()


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
	collision_shape.disabled = true


func get_chemical_info() -> Dictionary:
	return {
		"id": chemical_id,
		"nama": chemical_name,
		"kategori": chemical_category,
		"sifat": chemical_properties
	}
