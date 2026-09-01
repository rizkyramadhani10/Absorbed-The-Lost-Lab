extends Area2D 

@export_group("Portal Settings")
@export var quiz_flag_name: String = "is_quiz_completed"

@onready var interact_label: Label = get_node_or_null("Label") as Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if interact_label:
		interact_label.visible = false

	if Global.get(quiz_flag_name) == true:
		aktifkan_portal(false) 
	else:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		scale = Vector2.ZERO 

func aktifkan_portal(gunakan_animasi: bool = true) -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	
	if gunakan_animasi:
		scale = Vector2.ZERO
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, 0.8)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
		print("🚀 SUKSES: Portal menerima sinyal dan membesar!")
	else:
		scale = Vector2.ONE

# --- DETEKSI PLAYER ---
func _on_body_entered(body: Node2D) -> void:
	if not visible: return
		
	if body.name == "Player" or body.is_in_group("player"):
		if "nearby_interactable" in body:
			body.nearby_interactable = self
		if interact_label:
			interact_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		if "nearby_interactable" in body and body.nearby_interactable == self:
			body.nearby_interactable = null
		if interact_label:
			interact_label.visible = false

# --- LOGIKA INTERAKSI (TAMAT) ---
func interact() -> void:
	if not visible: return
	
	pindah_ke_scene_tujuan()

func pindah_ke_scene_tujuan():
	Global.is_game_completed = true
	var tujuan_final = "res://systems/ui/main_menu/main_menu.tscn"
	
	# Jika kamu punya path khusus main menu di tempat lain, pastikan string di atas sesuai.
	# Atau jika ingin mengecek apakah file tujuan benar-arada, biarkan langsung dieksekusi.
		
	print("🔄 Memulangkan player ke: ", tujuan_final)
	
	# PAKE LOADING SCREEN TRANSITION
	if has_node("/root/TransitionScreen"):
		TransitionScreen.transition_to_scene(tujuan_final)
	else:
		# Fallback jika TransitionScreen tidak ditemukan
		get_tree().change_scene_to_file(tujuan_final)
