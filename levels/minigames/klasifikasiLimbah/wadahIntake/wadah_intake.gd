extends Control

@onready var slot_padat = $StickerSlot_Padat
@onready var slot_cair = $StickerSlot_Cair

# NODE AUDIO BARU DI LINGKUP INTAKE
@onready var sfx_toss = $SFXToss
@onready var sfx_sticker_place = $SFXStickerPlace
@onready var sfx_sticker_wrong = $SFXStickerWrong

var memori_mesin = {
	"padat": {"daftar_limbah": [], "stiker_simbol": ""},
	"cair": {"daftar_limbah": [], "stiker_simbol": ""}
}

func validasi_can_drop_terpisah(lubang: String, data: Variant, nama_node_pengirim: String) -> bool:
	var nama_node_lowered = nama_node_pengirim.to_lower()
	var main_script = get_parent()
	
	if data["jenis"] == "limbah":
		if "intake" in nama_node_lowered:
			return data["wujud"] == lubang
		return false
		
	if data["jenis"] == "stiker":
		if "slot" in nama_node_lowered:
			if main_script.has_method("cek_apakah_baki_limbah_habis"):
				return main_script.cek_apakah_baki_limbah_habis()
		return false
		
	return false

func eksekusi_drop_terpisah(lubang: String, data: Variant) -> void:
	if data["jenis"] == "limbah":
		var data_simpan = {
			"nama": data["nama"],
			"simbol": data["simbol"]
		}
		memori_mesin[lubang]["daftar_limbah"].append(data_simpan)
		data["node_asal"].visible = false
		
		# SFX: Limbah dibuang masuk corong
		if sfx_toss: sfx_toss.play()
		print("Limbah [", data["nama"], "] masuk ke antrean kloter ", lubang.to_upper())
		
	elif data["jenis"] == "stiker":
		memori_mesin[lubang]["stiker_simbol"] = data["simbol"]
		tempel_gambar_stiker(lubang, data["node_asal"].texture)
		
		# SFX: Stiker dilepas menempel ke slot
		if sfx_sticker_place: sfx_sticker_place.play()
		print("Stiker [", data["simbol"], "] terpasang di slot ", lubang.to_upper())
		
		if memori_mesin["padat"]["stiker_simbol"] != "" and memori_mesin["cair"]["stiker_simbol"] != "":
			print("Kedua stiker terdeteksi lengkap! Memulai kalkulasi validasi...")
			await get_tree().create_timer(0.8).timeout
			evaluasi_jawaban_kolektif()

func tempel_gambar_stiker(lubang: String, teks: Texture2D):
	match lubang:
		"padat": slot_padat.texture = teks
		"cair": slot_cair.texture = teks

func evaluasi_jawaban_kolektif():
	var padat_benar = true
	var cair_benar = true
	
	var stiker_padat = memori_mesin["padat"]["stiker_simbol"]
	for limbah in memori_mesin["padat"]["daftar_limbah"]:
		if limbah["simbol"] != stiker_padat:
			padat_benar = false
			break
			
	var stiker_cair = memori_mesin["cair"]["stiker_simbol"]
	for limbah in memori_mesin["cair"]["daftar_limbah"]:
		if limbah["simbol"] != stiker_cair:
			cair_benar = false
			break
			
	if padat_benar and cair_benar:
		print("SEMPURNA! Kedua klasifikasi stiker kloter cocok!")
		tempel_gambar_stiker("padat", null)
		tempel_gambar_stiker("cair", null)
		get_parent().pemicu_menang()
	else:
		print("EVALUASI GAGAL: Ada stiker yang tidak sesuai dengan jenis isi limbah!")
		
		# SFX: Mainkan suara salah/gagal K3LH
		if sfx_sticker_wrong: sfx_sticker_wrong.play()
		
		get_parent().kurangi_hp(1)
		
		memori_mesin["padat"]["stiker_simbol"] = ""
		memori_mesin["cair"]["stiker_simbol"] = ""
		tempel_gambar_stiker("padat", null)
		tempel_gambar_stiker("cair", null)
