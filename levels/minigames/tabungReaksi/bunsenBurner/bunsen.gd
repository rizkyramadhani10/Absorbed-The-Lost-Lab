extends Node2D

# Status Bunsen
enum ApiSize { MATI, KECIL, SEDANG, BESAR }
var current_api: ApiSize = ApiSize.MATI
var is_on: bool = false

# Referensi node
@onready var sprite = $Sprite2D
@onready var area_pemanasan = $Area2D
@onready var tombol_nyala = $Button
@onready var slider_api = $VSlider

# Texture bisa di-drag drop dari inspector
@export var texture_mati: Texture2D
@export var texture_kecil: Texture2D
@export var texture_sedang: Texture2D
@export var texture_besar: Texture2D

# Kecepatan pemanasan berdasarkan besar api
var heating_rates = {
	ApiSize.KECIL: 30.0,
	ApiSize.SEDANG: 75.0,
	ApiSize.BESAR: 100.0
}

func _ready():
	# Setup slider
	slider_api.min_value = 0
	slider_api.max_value = 3
	slider_api.step = 1
	slider_api.value = 0
	slider_api.visible = false
	
	update_sprite()
	
	tombol_nyala.pressed.connect(_on_tombol_nyala_pressed)
	slider_api.value_changed.connect(_on_slider_changed)
	
	area_pemanasan.monitoring = false
	area_pemanasan.monitorable = false
	
	# 🔥 TAMBAHAN DEBUG: Koneksikan signal area
	area_pemanasan.area_entered.connect(_on_bunsen_area_entered)
	area_pemanasan.area_exited.connect(_on_bunsen_area_exited)
	
	_check_textures()
	print("✅ Bunsen siap, area_pemanasan = ", area_pemanasan.name)

# 🔥 FUNGSI DEBUG BARU
func _on_bunsen_area_entered(area):
	print("🔥🔥🔥 AREA MASUK BUNSEN! Area yang masuk: ", area.name, " (Parent: ", area.get_parent().name, ")")

func _on_bunsen_area_exited(area):
	print("❌ Area keluar dari Bunsen: ", area.name)

func _check_textures():
	if texture_mati == null:
		print("⚠️ Peringatan: texture_mati belum diisi di Inspector!")
	if texture_kecil == null:
		print("⚠️ Peringatan: texture_kecil belum diisi di Inspector!")
	if texture_sedang == null:
		print("⚠️ Peringatan: texture_sedang belum diisi di Inspector!")
	if texture_besar == null:
		print("⚠️ Peringatan: texture_besar belum diisi di Inspector!")

func _on_tombol_nyala_pressed():
	if !is_on:
		is_on = true
		current_api = ApiSize.KECIL
		slider_api.visible = true
		slider_api.value = 1
		area_pemanasan.monitoring = true
		area_pemanasan.monitorable = true
		update_sprite()
		print("🔥 Bunsen dinyalakan! (Api Kecil) - Area pemanasan AKTIF")
	else:
		is_on = false
		current_api = ApiSize.MATI
		slider_api.visible = false
		area_pemanasan.monitoring = false
		area_pemanasan.monitorable = false
		update_sprite()
		print("❌ Bunsen dimatikan - Area pemanasan NONAKTIF")

func _on_slider_changed(value: float):
	if !is_on:
		return
	
	var new_size = int(value)
	match new_size:
		0:
			current_api = ApiSize.MATI
			is_on = false
			slider_api.visible = false
			area_pemanasan.monitoring = false
			area_pemanasan.monitorable = false
			print("🔥 Bunsen mati karena slider ke 0")
		1:
			current_api = ApiSize.KECIL
			print("🔥 Api kecil - Kecepatan pemanasan: ", get_heating_rate())
		2:
			current_api = ApiSize.SEDANG
			print("🔥 Api sedang - Kecepatan pemanasan: ", get_heating_rate())
		3:
			current_api = ApiSize.BESAR
			print("🔥 Api besar - Kecepatan pemanasan: ", get_heating_rate())
	
	update_sprite()

func update_sprite():
	match current_api:
		ApiSize.MATI:
			if texture_mati:
				sprite.texture = texture_mati
		ApiSize.KECIL:
			if texture_kecil:
				sprite.texture = texture_kecil
		ApiSize.SEDANG:
			if texture_sedang:
				sprite.texture = texture_sedang
		ApiSize.BESAR:
			if texture_besar:
				sprite.texture = texture_besar

func get_heating_rate() -> float:
	if !is_on or current_api == ApiSize.MATI:
		return 0.0
	return heating_rates[current_api]
