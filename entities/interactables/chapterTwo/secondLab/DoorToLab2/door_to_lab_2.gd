extends Area2D

@export_file("*.tscn") var target_scene_path: String
@export var target_spawn: String = ""

# 🔒 Syarat progress cerita agar pintu bisa dibuka
@export var required_stage: GameState.StoryStage = GameState.StoryStage.POST_SHOWER
# 📄 Path file resource dialog locked .tres
@export_file("*.tres") var locked_dialog_path: String = ""

# 📈 PENGATURAN PROGRESS CERITA SETELAH LEWAT PINTU (TAMBAHAN BARU)
@export var change_stage_on_enter: bool = false
@export var next_stage: GameState.StoryStage = GameState.StoryStage.ENTERED_LAB1

@onready var door_sprite = $DoorToLab2
@onready var dim_overlay = $DimOverlay
@onready var interaction_hint = $Label
@onready var sfx_player = $AudioStreamPlayer2D

var player_nearby: bool = false
var fade_tween: Tween

var player_ref: Node2D = null
var is_dialog_playing: bool = false

func _ready() -> void:
	interaction_hint.visible = false
	door_sprite.modulate.a = 0.15
	dim_overlay.modulate.a = 0.0
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("interact") and not is_dialog_playing:
		
		# 🔒 CEK PROGRESS CERITA UNTUK MEMBUKA PINTU
		if GameState.current_stage < required_stage:
			_play_locked_dialog()
			return
			
		# 🚪 PROSES PINDAH SCENE
		if target_scene_path != "":
			player_nearby = false 
			interaction_hint.visible = false
			
			Global.spawn_point = target_spawn
			
			if sfx_player:
				sfx_player.play()
				
			# 🔥 PERBAIKAN: Hanya update stage jika diset 'True' DAN stage pemain saat ini masih di bawah target stage
			if change_stage_on_enter and GameState.current_stage < next_stage:
				GameState.current_stage = next_stage
				
			TransitionScreen.transition_to_scene(target_scene_path)
		else:
			print("Warning: No target scene path set for this door!")

func _play_locked_dialog() -> void:
	if locked_dialog_path == "":
		print("ERROR: 'Locked Dialog Path' di Inspector masih KOSONG!")
		return

	if player_ref == null:
		return

	var dp = player_ref.get_node_or_null("DialogPlayer")
	if dp == null:
		dp = player_ref.find_child("DialogPlayer", true, false)

	if dp == null:
		print("ERROR: Node 'DialogPlayer' tidak ditemukan pada " + player_ref.name)
		return

	is_dialog_playing = true

	player_ref.set_physics_process(false)
	if player_ref.has_method("set_process_unhandled_input"):
		player_ref.set_process_unhandled_input(false)

	var dialogue_resource = load(locked_dialog_path)
	dp._dialog_data = dialogue_resource
	dp.start()

	await dp.dialog_ended

	player_ref.set_physics_process(true)
	if player_ref.has_method("set_process_unhandled_input"):
		player_ref.set_process_unhandled_input(true)

	is_dialog_playing = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = true
		player_ref = body
		interaction_hint.visible = true
		_animate_environment(1.0, 0.65)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = false
		player_ref = null
		interaction_hint.visible = false
		_animate_environment(0.15, 0.0)

func _animate_environment(door_alpha: float, overlay_alpha: float) -> void:
	if fade_tween:
		fade_tween.kill()
		
	fade_tween = create_tween().set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	fade_tween.tween_property(door_sprite, "modulate:a", door_alpha, 0.5)
	fade_tween.tween_property(dim_overlay, "modulate:a", overlay_alpha, 0.5)
