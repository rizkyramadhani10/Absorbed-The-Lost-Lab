extends Area2D

@export var category : String

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var snap_point: Marker2D = $SnapPoint


func _ready() -> void:
	# Debug info untuk memastikan slot siap digunakan
	if collision and collision.shape:
		print("Slot ", name, " dengan kategori: ", category, " siap digunakan")
		print("  - Shape terdeteksi: ", collision.shape.get_class())
	else:
		print("⚠️ WARNING: Slot ", name, " tidak memiliki collision shape!")


func is_point_inside(point: Vector2) -> bool:
	"""Cek apakah sebuah point berada di dalam area collision slot"""
	if not collision or collision.shape == null:
		return false
	
	var shape = collision.shape
	
	# Untuk RectangleShape2D
	if shape is RectangleShape2D:
		var rect = get_rect()
		return rect.has_point(point)
	
	# Untuk CircleShape2D (jika kamu pakai)
	elif shape is CircleShape2D:
		var center = collision.global_position
		var radius = shape.radius
		return point.distance_to(center) <= radius
	
	# Untuk CapsuleShape2D (jika kamu pakai)
	elif shape is CapsuleShape2D:
		# Approximate dengan circle untuk simplicity
		var center = collision.global_position
		var radius = shape.radius
		return point.distance_to(center) <= radius
	
	return false


func get_rect() -> Rect2:
	"""Mendapatkan rectangle area collision dalam koordinat global"""
	if collision == null or collision.shape == null:
		return Rect2()
	
	var shape := collision.shape as RectangleShape2D
	if shape == null:
		return Rect2()
	
	# posisi collision dalam koordinat global
	var center := collision.global_position
	var size := shape.size
	
	return Rect2(
		center - size / 2.0,
		size
	)


func get_snap_position() -> Vector2:
	"""Mendapatkan posisi snap point dalam koordinat global"""
	if snap_point:
		return snap_point.global_position
	return global_position  # Fallback ke posisi slot
