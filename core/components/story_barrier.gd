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
		
	# 🔥 DEBUG LOG: Cek di Console output nilai stage saat ini vs appear stage
	print("--- STORY BARRIER CHECK ---")
	print("Current Stage: ", GameState.current_stage)
	print("Appear Stage : ", appear_stage)
	
	update_barrier_state()

func _process(_delta: float) -> void:
	update_barrier_state()

func update_barrier_state() -> void:
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
			if locked_dialog_path == "":
				print("ERROR StoryBarrier: Path dialog kosong!")
				return
			
			var dp = body.find_child("DialogPlayer", true, false)
			if dp == null:
				return

			is_dialog_playing = true
			await get_tree().process_frame

			body.set_physics_process(false)
			if body.has_method("set_process_unhandled_input"):
				body.set_process_unhandled_input(false)
			
			var dialogue_resource = load(locked_dialog_path)
			dp._dialog_data = dialogue_resource
			dp.start()
			
			await dp.dialog_ended
			
			body.set_physics_process(true)
			if body.has_method("set_process_unhandled_input"):
				body.set_process_unhandled_input(true)
				
			is_dialog_playing = false
