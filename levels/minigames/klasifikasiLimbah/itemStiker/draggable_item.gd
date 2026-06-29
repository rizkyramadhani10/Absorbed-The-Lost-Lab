extends TextureRect

# Menentukan apakah node ini "limbah" atau "stiker"
@export_enum("limbah", "stiker") var jenis_item: String = "limbah"

@export var nama_item: String = "Asam Sulfat"
# Hapus pilihan "gas" di sini
@export_enum("padat", "cair") var wujud_limbah: String = "cair" 
@export var simbol_k3: String = "korosif" 

func _get_drag_data(_at_position: Vector2) -> Variant:
	# 1. Buat control node utama sebagai container preview
	var preview_container = Control.new()
	
	# 2. Buat TextureRect seperti biasa
	var preview_texture = TextureRect.new()
	preview_texture.texture = texture
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.custom_minimum_size = size
	
	# 3. Geser posisi TextureRect setengah dari ukurannya ke arah kiri dan atas
	preview_texture.position = -size / 2
	
	# 4. Masukkan texture ke dalam container
	preview_container.add_child(preview_texture)
	
	# 5. Gunakan container sebagai drag preview
	set_drag_preview(preview_container)
	
	return {
		"jenis": jenis_item,
		"nama": nama_item,
		"wujud": wujud_limbah,
		"simbol": simbol_k3,
		"node_asal": self
	}
