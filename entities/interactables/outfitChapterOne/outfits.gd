extends Area2D

var is_taken: bool = false

func _ready():
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

func _on_body_entered(body):
	if body.name == "Player" and not is_taken:
		body.nearby_interactable = self
		show_interact_prompt(true)

func _on_body_exited(body):
	if body.name == "Player":
		if body.nearby_interactable == self:
			body.nearby_interactable = null
		show_interact_prompt(false)

func show_interact_prompt(show: bool):
	var prompt = $InteractPrompt if has_node("InteractPrompt") else null
	if prompt:
		prompt.visible = show

func interact():
	if is_taken:
		return
		
	print("Player berinteraksi untuk memakai baju APD!")
	is_taken = true
	show_interact_prompt(false)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("wear_apd_suit"):
		player.wear_apd_suit()

# Fungsi ini akan dipanggil oleh Player saat animasinya benar-benar selesai
func hide_suit():
	if has_node("Sprite2D"):
		$Sprite2D.visible = false
	monitoring = false # Matikan area setelah sprite menghilang
