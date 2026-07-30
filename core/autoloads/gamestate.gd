# GameState.gd (Tambahkan ke Project Settings -> Autoloads)
extends Node

# Enum atau Integer untuk melacak milestone cerita
enum StoryStage {
	AWAKE,                  # Baru bangun/sadar
	POST_SHOWER,            # Selesai safety shower
	ENTERED_LAB1,           # Masuk lab 1 (lockdown)
	CHECKED_MONITOR,        # Selesai cek monitor workspace
	CHECKED_TIME_MACHINE,   # Selesai cek mesin waktu
	FOUND_BATTERY,          # Menemukan baterai di gudang
	REACHED_OUTSIDE,        # Sudah berada di luar (masa lalu)
	REACHED_CRATER,         # Di dekat kawah vulkanik
	OBTAINED_RESOURCE,      # Sudah mengambil bongkahan
	BACK_TO_LAB             # Kembali ke lab untuk meracik
}

var current_stage: StoryStage = StoryStage.AWAKE

# Menyimpan status quest/objektif opsional
var has_empty_battery: bool = false

# Variabel untuk crafting
var has_wood: bool = false
var has_rope: bool = false
var has_stone: bool = false
var has_hammer: bool = false
