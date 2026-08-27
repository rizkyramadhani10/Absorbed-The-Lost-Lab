extends Node

# Variabel ini akan menyimpan status apakah minigame pemanasan sudah selesai
var is_heating_completed: bool = false
var is_shower_completed: bool = false
var is_quiz_completed: bool = false
var is_check_monitor: bool = false
var is_battery_found: bool = false
var is_trigger_time_machine: bool = false
var is_trigger_amnesia: bool = false
var has_apd: bool = false
var scene_asal_path: String = ""
var limbah_minigame_completed: bool = false
var player_last_position: Vector2 = Vector2.ZERO
var player_last_flip: bool = false
var last_room = ""
var spawn_point = ""
var minigame_penataan_completed: bool = false
var active_dialog_player: Node = null
var has_wood: bool = false
var has_rope: bool = false
var has_stone: bool = false
var has_hammer: bool = false
var is_trigger_meadow: bool = false
var is_trigger_volcanic: bool = false
var is_tablet_open: bool = false
var is_sulfur_destroyed: bool = false
var materials_collected: bool = false
var is_game_completed: bool = false
# Di Global.gd atau gamestate.gd

# --- VARIABEL PENGETAHUAN LAB ---
var knowledge_unlocked: Dictionary = {
	"incubator": false,
	"autoclave": false,
	"microscope": false,
	"spectrophotometer": false,
	"sonicator": false,
	"ph_meter": false,
	"laboratory_refrigerator": false,
	"burette_cabinet": false,
	"thermo_scientific": false,
	"analytical_balance": false,
	"fume_hood": false,
	"burette_clamp": false,
	"aquades_dispenser": false,
	"safety_shower": false,
	# Tambahkan key lain jika ada alat tambahan
}

# Fungsi untuk mengecek apakah semua pengetahuan sudah terkumpul (opsional)
func is_all_knowledge_unlocked() -> bool:
	for key in knowledge_unlocked:
		if not knowledge_unlocked[key]:
			return false
	return true

# Fungsi untuk mendapatkan jumlah pengetahuan yang sudah dikumpulkan
func get_knowledge_count() -> int:
	var count: int = 0
	for key in knowledge_unlocked:
		if knowledge_unlocked[key]:
			count += 1
	return count

# Fungsi untuk mendapatkan total pengetahuan
func get_total_knowledge() -> int:
	return knowledge_unlocked.size()
