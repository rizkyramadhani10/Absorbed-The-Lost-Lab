extends Node

# Variabel ini akan menyimpan status apakah minigame pemanasan sudah selesai
var is_heating_completed: bool = false
var is_shower_completed: bool = false
var is_quiz_completed: bool = false
var has_apd: bool = false
var scene_asal_path: String = ""
var limbah_minigame_completed: bool = false
var player_last_position: Vector2 = Vector2.ZERO
var player_last_flip: bool = false
var last_room = ""
var spawn_point = ""
var minigame_penataan_completed: bool = false
var is_first_time_play: bool = true
var active_dialog_player: Node = null
var has_wood: bool = false
var has_rope: bool = false
var has_stone: bool = false
var has_hammer: bool = false
var is_tablet_open: bool = false
var is_sulfur_destroyed: bool = false
var materials_collected: bool = false
