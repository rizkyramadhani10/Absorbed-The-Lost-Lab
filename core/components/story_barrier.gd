extends Node2D

@export var appear_stage: GameState.StoryStage = GameState.StoryStage.CHECKED_TIME_MACHINE
@export var required_stage: GameState.StoryStage = GameState.StoryStage.FOUND_BATTERY
@export_file("*.tres") var locked_dialog_path: String = ""

@onready var trigger_area: Area2D = $Area2D

# 🛠️ Cari node tembok fisik (StaticBody2D) jika barrier kamu punya tembok penghalang
@onready var static_body: StaticBody2D = $StaticBody2D if has_node("StaticBody2D") else null

var is_dialog_playing: bool = false

func _ready() -> void:
	if not trigger_area.body_entered.is_connected(_on_body_entered):
		trigger_area.body_entered.connect(_on_body_entered)
		
	# Event-driven: cukup update saat stage berubah, bukan setiap frame
	GameState.stage_changed.connect(update_barrier_state)
	
	update_barrier_state()

func update_barrier_state(_new_stage: GameState.StoryStage = GameState.StoryStage.AWAKE) -> void:
	# 1. Hancurkan barrier jika sudah melewai required_stage
	if GameState.current_stage >= required_stage:
		queue_free()
		return

	# 2. Jika stage saat ini masih KURANG dari appear_stage -> SEMBUNYIKAN & MATIKAN FISIK
	if GameState.current_stage < appear_stage:
		visible = false
		trigger_area.set_deferred("monitoring", false)
		trigger_area.set_deferred("monitorable", false)
		
		# Matikan tabrakan tembok fisik jika ada
		if static_body:
			static_body.process_mode = PROCESS_MODE_DISABLED
			
	else:
		# 3. Tampilkan & Aktifkan hanya jika stage sudah mencapai/melewati appear_stage
		visible = true
		trigger_area.set_deferred("monitoring", true)
		trigger_area.set_deferred("monitorable", true)
		
		# Aktifkan tembok fisik
		if static_body:
			static_body.process_mode = PROCESS_MODE_INHERIT

func _on_body_entered(body: Node2D) -> void:
	if GameState.current_stage < appear_stage or is_dialog_playing:
		return

	if body.name == "Player" or body.is_in_group("player"):
		if GameState.current_stage < required_stage:
			is_dialog_playing = true
			await get_tree().process_frame
			
			# Lock dialog + kunci/buka kontrol player ditangani PlayerGate
			await PlayerGate.play_locked_dialog(body, locked_dialog_path)
				
			is_dialog_playing = false
