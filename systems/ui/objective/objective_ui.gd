extends CanvasLayer # Atau sesuaikan dengan tipe node ObjectiveUI milikmu

# Ambil referensi ke node RichTextLabel
# (Pastikan path ini sesuai dengan susunan node-mu yang terbaru, 
# jika kamu memakai PanelContainer, ubah menjadi $Control/PanelContainer/RichTextLabel)
@onready var label = $Control/RichTextLabel

var stage_objectives: Dictionary = {
	GameState.StoryStage.AWAKE: "Pergi ke Safety Shower untuk dekontaminasi.",
	GameState.StoryStage.POST_SHOWER: "Masuk ke dalam Lab 1.",
	GameState.StoryStage.ENTERED_LAB1: "Selesaikan prosedur pengelolaan limbah.",
	GameState.StoryStage.WASTE_MANAGEMENT: "Segera menuju ke area Workspace.",
	GameState.StoryStage.NEED_CHECK_WORKSPACE: "Periksa monitor di Workspace.",
	GameState.StoryStage.CHECKED_MONITOR: "Periksa kondisi Mesin Waktu.",
	GameState.StoryStage.CHECKED_TIME_MACHINE: "Rapikan barang-barang di Gudang Penyimpanan.",
	GameState.StoryStage.MANAGE_STORAGE: "Cari Baterai yang tersimpan di Gudang.",
	GameState.StoryStage.FOUND_BATTERY: "Pergi ke luar lab menuju masa lalu.",
	GameState.StoryStage.REACHED_OUTSIDE: "Jelajahi area dan temukan kawah vulkanik.",
	GameState.StoryStage.REACHED_CRATER: "Cari material (Batu, Kayu, Tali) di sekitar kawah.",
	GameState.StoryStage.FOUND_STONE: "Batu ditemukan. Lanjutkan mencari Kayu dan Tali.",
	GameState.StoryStage.FOUND_WOOD: "Kayu ditemukan. Lanjutkan mencari Tali.",
	GameState.StoryStage.FOUND_ROPE: "Semua bahan terkumpul. Buat Kapak sekarang.",
	GameState.StoryStage.MADE_AXE: "Gunakan Kapak untuk menambang bongkahan.",
	GameState.StoryStage.OBTAINED_RESOURCE: "Bongkahan didapat! Segera kembali ke Lab.",
	GameState.StoryStage.BACK_TO_LAB: "Ekstrak asam sulfat dari sulfur yang telah ditambang.",
	
	# --- TAMBAHAN STAGE BARU ---
	GameState.StoryStage.DESTILATION: "Isi ulang daya Baterai di komputer sebelah kanan mesin waktu.",
	GameState.StoryStage.CHARGE_BATTERY: "Jawab kuis verifikasi sistem dengan benar.",
	GameState.StoryStage.PASSED_QUIZ: "Sistem aktif! Masuk ke dalam Mesin Waktu.",
}

func _ready() -> void:
	GameState.stage_changed.connect(_on_stage_changed)
	_update_text(GameState.current_stage)

func _on_stage_changed(new_stage: int) -> void:
	_update_text(new_stage)
	
	# Panggil modulate dan tween pada variabel 'label', bukan pada 'self'
	label.modulate = Color(1, 0.8, 0)
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1), 0.6)

func _update_text(stage: int) -> void:
	# Karena PUT_BATTERY tidak ada di dictionary, pengecekan ini 
	# akan mengabaikannya secara otomatis dan teks UI tidak akan error/hilang.
	if stage_objectives.has(stage):
		label.text = "Misi: " + stage_objectives[stage]
