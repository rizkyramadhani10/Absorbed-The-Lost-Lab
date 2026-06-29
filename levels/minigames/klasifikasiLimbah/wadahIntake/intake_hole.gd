extends Control

@export_enum("padat", "cair") var jenis_lubang: String = "padat"
@onready var mesin_utama = get_parent() 

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var izin = mesin_utama.validasi_can_drop_terpisah(jenis_lubang, data, str(name))
	
	# LAPORAN DETEKTIF:
	print(">> KURSOR MENYENTUH NODE: [", name, "] | Bawa barang: ", data["jenis"], " | Izin: ", izin)
	return izin

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	mesin_utama.eksekusi_drop_terpisah(jenis_lubang, data)
