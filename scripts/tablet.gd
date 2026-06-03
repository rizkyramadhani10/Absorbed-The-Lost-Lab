extends Area2D

@export var is_quiz: bool = false
# 1. Ubah nama variabel agar lebih umum (bisa untuk tablet, berkas laboratorium, dll)
@export var tablet_text: String = "Mengunduh data log lab..."

# DRAG AND DROP: Seret scene tablet_view.tscn atau whiteboard_view.tscn ke sini dari FileSystem
@export var tablet_view_scene: PackedScene = null

# DRAG AND DROP: Seret node Game / Main scene ke sini dari Scene Tree
@export var game_world: Node = null

var tablet_view_instance = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
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
	print("Interaksi dengan tablet!")
	
	# Cek apakah scene view sudah di-drag ke Inspector
	if tablet_view_scene == null:
		print("ERROR: Belum drag tablet_view_scene ke inspector!")
		return
	
	# Cek apakah game_world sudah di-drag
	if game_world == null:
		print("ERROR: Belum drag game_world ke inspector!")
		return
	
	# Cari player dari group
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("ERROR: Player tidak ditemukan! Pastikan player sudah masuk group 'player'")
		return
	
	# Buat instance UI popup untuk tablet
	if tablet_view_instance == null:
		tablet_view_instance = tablet_view_scene.instantiate()
		get_tree().root.add_child(tablet_view_instance)
	
	# PENTING: Sesuaikan nama variabel internal pada scene tablet UI kamu.
	# Jika script UI tablet menggunakan nama variabel 'whiteboard_text', biarkan tetap 'whiteboard_text'.
	# Di sini kita asumsikan variabel UI-nya fleksibel/bisa menerima string teks:
	if "whiteboard_text" in tablet_view_instance:
		tablet_view_instance.whiteboard_text = tablet_text
	elif "tablet_text" in tablet_view_instance:
		tablet_view_instance.tablet_text = tablet_text
		
	tablet_view_instance.open(game_world, player)
	
	
