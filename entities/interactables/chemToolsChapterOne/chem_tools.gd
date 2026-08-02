extends Area2D

@export_file("*.tscn") var target_scene_path: String = ""
@export var completion_flag: String = "is_heating_completed" 
@export var advance_story_to: GameState.StoryStage = GameState.StoryStage.POST_SHOWER
var player_ref: Node2D = null

func _ready():
	# Cek variabel secara dinamis
	if Global.get(completion_flag) == true:
		
		# 🔥 Tunda 1 frame agar Node lain (seperti LevelManager) selesai _ready()
		await get_tree().process_frame
		
		# 🔥 Majukan progres cerita jika belum mencapai target stage
		if GameState.current_stage < advance_story_to:
			GameState.current_stage = advance_story_to
			print("Progres cerita diperbarui ke: ", GameState.current_stage)
			
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = true
		show_interact_prompt(false)
		return 

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	show_interact_prompt(false)

func _on_body_entered(body):
	if body.name == "Player":
		player_ref = body 
		body.nearby_interactable = self
		show_interact_prompt(true)

func _on_body_exited(body):
	if body.name == "Player":
		player_ref = null 
		if body.nearby_interactable == self:
			body.nearby_interactable = null
		show_interact_prompt(false)

func show_interact_prompt(show: bool):
	var prompt = $Label if has_node("Label") else null
	if prompt:
		prompt.visible = show

func interact():
	# 🔥 Cek variabel secara dinamis
	if Global.get(completion_flag) == true:
		print("Interaksi ditolak: Alat ini sudah sukses digunakan!")
		return

	if target_scene_path == "":
		print("ERROR: Path target scene kosong! Isi di Inspector.")
		return
	
	# Pencatat Posisi & Flip
	Global.scene_asal_path = get_tree().current_scene.scene_file_path
	if player_ref:
		Global.player_last_position = player_ref.global_position
		Global.player_last_flip = player_ref.animated_sprite.flip_h
		
	print("Interaksi dengan alat kimia, mencatat posisi: ", Global.player_last_position)
		
	var error_code = get_tree().change_scene_to_file(target_scene_path)
	if error_code != OK:
		print("ERROR: Gagal pindah scene. Kode Error: ", error_code)
