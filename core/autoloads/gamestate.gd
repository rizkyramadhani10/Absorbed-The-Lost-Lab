# GameState.gd (Tambahkan ke Project Settings -> Autoloads)
extends Node

signal stage_changed(new_stage)

# Enum atau Integer untuk melacak milestone cerita
enum StoryStage {
	AWAKE,                  # Baru bangun/sadar
	POST_SHOWER,            # Selesai safety shower
	ENTERED_LAB1,           # Masuk lab 1 (lockdown)
	WASTE_MANAGEMENT,       # Minigame limbah
	NEED_CHECK_WORKSPACE,   # Segera ke Workspace
	CHECKED_MONITOR,        # Selesai cek monitor workspace
	CHECKED_TIME_MACHINE,   # Selesai cek mesin waktu
	MANAGE_STORAGE,         # Selesai merapihkan gudang penyimpanan
	FOUND_BATTERY,          # Menemukan baterai di gudang
	REACHED_OUTSIDE,        # Sudah berada di luar (masa lalu)
	REACHED_CRATER,         # Di dekat kawah vulkanik
	FOUND_STONE,            # Menemukan batu
	FOUND_WOOD,             # Menemukan kayu
	FOUND_ROPE,             # Menemukan tali
	MADE_AXE,               # Membuat kapak
	OBTAINED_RESOURCE,      # Sudah mengambil bongkahan
	BACK_TO_LAB,            # Kembali ke lab untuk meracik
	DESTILATION,
	CHARGE_BATTERY,
	PUT_BATTERY,
	PASSED_QUIZ,
	ENTER_TIME_MACHINE
}

var current_stage: StoryStage = StoryStage.AWAKE:
	set(value):
		# Hanya emit sinyal jika nilainya benar-benar berubah
		if current_stage != value:
			current_stage = value
			stage_changed.emit(current_stage) # Pancarkan sinyal tiap kali stage berubah

func advance_to(new_stage: StoryStage) -> void:
	# Hanya ubah jika stage baru LEBIH TINGGI dari stage saat ini
	if current_stage < new_stage:
		current_stage = new_stage
		# (Opsional) Sangat berguna untuk mengecek log saat main/testing
		print("✅ Cerita maju ke stage: ", new_stage)
