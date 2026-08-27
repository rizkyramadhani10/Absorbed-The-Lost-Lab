extends Area2D

# 📄 Path file resource dialog locked .tres
@export_file("*.tres") var locked_dialog_path: String = ""

var is_taken: bool = false
var player_nearby: bool = false 
var player_ref: Node2D = null
var is_dialog_playing: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	show_interact_prompt(false)
	
	# Jika player sudah pakai APD, hilangkan baju yang di lantai
	if Global.has_apd:
		is_taken = true
		if has_node("Sprite2D"):
			$Sprite2D.visible = false
		monitoring = false

func _unhandled_input(event: InputEvent) -> void:
	# Cek tambahan "not is_dialog_playing" agar input tidak dobel
	if player_nearby and not is_taken and event.is_action_pressed("interact") and not is_dialog_playing:
		interact()

func _on_body_entered(body: Node2D) -> void:
	if (body.name == "Player" or body.is_in_group("player")) and not is_taken:
		player_nearby = true
		player_ref = body
		show_interact_prompt(true)
		
		if "nearby_interactable" in body:
			body.nearby_interactable = self

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = false
		player_ref = null
		show_interact_prompt(false)
		
		if "nearby_interactable" in body and body.nearby_interactable == self:
			body.nearby_interactable = null

func show_interact_prompt(show: bool) -> void:
	var prompt = $Label
	if prompt:
		prompt.visible = show

func interact() -> void:
	if is_taken:
		return
		
	# 🔒 CEK PROGRESS: Harus cek komputer dulu
	# Pastikan nama variabel sesuai di Global (misal: "is_check_monitor")
	if not Global.get("is_check_monitor"):
		_play_locked_dialog()
		return
		
	print("Player berinteraksi untuk memakai baju APD!")
	is_taken = true
	player_nearby = false
	show_interact_prompt(false)
	
	Global.has_apd = true
	
	if player_ref and player_ref.has_method("wear_apd_suit"):
		player_ref.wear_apd_suit()

func hide_suit() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.visible = false
	monitoring = false

# 💬 Fungsi memunculkan dialog pada Player
func _play_locked_dialog() -> void:
	if locked_dialog_path == "":
		print("ERROR di Outfits: 'Locked Dialog Path' di Inspector masih KOSONG!")
		return

	if player_ref == null:
		return

	is_dialog_playing = true
	# Lock dialog + kunci/buka kontrol player ditangani PlayerGate
	await PlayerGate.play_locked_dialog(player_ref, locked_dialog_path)
	is_dialog_playing = false
