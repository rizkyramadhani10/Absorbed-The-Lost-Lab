class_name PlayerGate
extends RefCounted

## Helper statis terpusat untuk mengunci/membuka input Player selama dialog,
## plus pencarian & pemutaran DialogPlayer milik Player.
## Menggantikan pola copy-paste lock -> dialog -> unlock di banyak file.

# Cache resource dialog agar load() tidak berulang untuk path yang sama
static var _dialog_cache: Dictionary = {}


## Kunci pergerakan & input player
static func lock(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	player.set_physics_process(false)
	if player.has_method("set_process_unhandled_input"):
		player.set_process_unhandled_input(false)


## Buka kunci pergerakan & input player (aman jika node sudah freed)
static func unlock(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	player.set_physics_process(true)
	if player.has_method("set_process_unhandled_input"):
		player.set_process_unhandled_input(true)


## Cari node DialogPlayer pada player (langsung atau nested)
static func find_dialog_player(player: Node) -> Node:
	if player == null or not is_instance_valid(player):
		return null
	var dp: Node = player.get_node_or_null("DialogPlayer")
	if dp == null:
		dp = player.find_child("DialogPlayer", true, false)
	return dp


## Muat resource dialog dengan cache (menghindari disk I/O berulang)
static func get_dialog_resource(dialog_path: String) -> Resource:
	if dialog_path == "":
		return null
	if _dialog_cache.has(dialog_path):
		return _dialog_cache[dialog_path]
	var res: Resource = load(dialog_path)
	if res != null:
		_dialog_cache[dialog_path] = res
	return res


## Putar dialog locked sambil mengunci kontrol player.
## Pemanggil cukup: `await PlayerGate.play_locked_dialog(player_ref, path)`
static func play_locked_dialog(player: Node, dialog_path: String) -> void:
	if dialog_path == "":
		push_error("PlayerGate: Path dialog locked kosong!")
		return

	var dp := find_dialog_player(player)
	if dp == null:
		push_error("PlayerGate: Node 'DialogPlayer' tidak ditemukan pada " + str(player.name if player else "null"))
		return

	lock(player)

	var dialogue_resource := get_dialog_resource(dialog_path)
	if dialogue_resource == null:
		unlock(player)
		return

	dp._dialog_data = dialogue_resource
	dp.start()

	await dp.dialog_ended

	unlock(player)
