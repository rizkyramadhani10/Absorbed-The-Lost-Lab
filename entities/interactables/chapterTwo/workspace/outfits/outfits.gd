extends Area2D

var is_taken: bool = false
var player_nearby: bool = false # Tambahan dari Script 2

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 🔥 FIX: Sembunyikan prompt interaksi saat awal scene dimuat/di-render
	show_interact_prompt(false)
	
	# 🔥 TAMBAHAN: Jika player sudah pakai APD, hilangkan baju yang di lantai
	if Global.has_apd:
		is_taken = true
		if has_node("Sprite2D"):
			$Sprite2D.visible = false
		monitoring = false # Matikan areanya juga

func _unhandled_input(event: InputEvent) -> void: # Mengikuti pola Script 2
	if player_nearby and not is_taken and event.is_action_pressed("interact"):
		interact()

func _on_body_entered(body: Node2D) -> void: # Menggunakan logic deteksi Script 2
	if (body.name == "Player" or body.is_in_group("player")) and not is_taken:
		player_nearby = true
		show_interact_prompt(true)
		
		# Opsional: Tetap dipasang jika script Player kamu membutuhkan referensi ini
		if "nearby_interactable" in body:
			body.nearby_interactable = self

func _on_body_exited(body: Node2D) -> void: # Menggunakan logic deteksi Script 2
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = false
		show_interact_prompt(false)
		
		# Bersihkan referensi di player jika ada
		if "nearby_interactable" in body and body.nearby_interactable == self:
			body.nearby_interactable = null

func show_interact_prompt(show: bool) -> void:
	var prompt = $Label
	if prompt:
		prompt.visible = show

func interact() -> void:
	if is_taken:
		return
		
	print("Player berinteraksi untuk memakai baju APD!")
	is_taken = true
	player_nearby = false
	show_interact_prompt(false)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("wear_apd_suit"):
		player.wear_apd_suit()

# Fungsi ini akan dipanggil oleh Player saat animasinya benar-benar selesai
func hide_suit() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.visible = false
	monitoring = false # Matikan area setelah sprite menghilang
