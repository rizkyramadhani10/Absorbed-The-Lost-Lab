extends Area2D
class_name InteractableDoor

## Script pintu teleport TERPADU.
## Menggantikan 12 script pintu duplikat (to_meadow, to_forest, exit_door,
## door_to_lab_1/2, door_to_second_lab, dll). Semua fitur menjadi opsional
## lewat export di Inspector:
##   - Teleport biasa            : isi target_scene_path (+ target_spawn)
##   - Pintu terkunci stage      : set required_stage > AWAKE + locked_dialog_path
##   - Pintu terkunci APD        : aktifkan require_apd + locked_dialog_path
##   - Majukan cerita saat lewat : aktifkan change_stage_on_enter + next_stage
##   - Efek highlight pintu      : isi door_sprite_path / dim_overlay_path
##   - SFX                       : otomatis jika scene punya child AudioStreamPlayer2D

@export_group("Teleport")
@export_file("*.tscn") var target_scene_path: String
@export var target_spawn: String = ""

@export_group("Kunci Pintu")
# 🔒 Syarat progress cerita agar pintu bisa dibuka (AWAKE = selalu terbuka)
@export var required_stage: GameState.StoryStage = GameState.StoryStage.AWAKE
# 🚧 Gate alternatif: player wajib memakai APD dulu
@export var require_apd: bool = false
# 📄 Path file resource dialog locked .tres
@export_file("*.tres") var locked_dialog_path: String = ""

@export_group("Progress Cerita")
# 📈 Majukan progress cerita setelah player melewati pintu
@export var change_stage_on_enter: bool = false
@export var next_stage: GameState.StoryStage = GameState.StoryStage.ENTERED_LAB1

@export_group("Efek Visual")
# ✨ Opsional: sprite pintu & overlay yang di-dim saat player tidak di dekatnya
@export_node_path("CanvasItem") var door_sprite_path: NodePath = ^""
@export_node_path("CanvasItem") var dim_overlay_path: NodePath = ^""
@export_range(0.0, 1.0) var idle_door_alpha: float = 0.15
@export_range(0.0, 1.0) var near_door_alpha: float = 1.0
@export_range(0.0, 1.0) var near_overlay_alpha: float = 0.65

@export_group("Lain-lain")
# Reset posisi terakhir player sebelum pindah (agar tidak restore ke titik lama)
@export var reset_last_position_on_enter: bool = false

@onready var interaction_hint: CanvasItem = get_node_or_null("Label")
@onready var sfx_player: AudioStreamPlayer2D = get_node_or_null("AudioStreamPlayer2D")
@onready var door_sprite: CanvasItem = get_node_or_null(door_sprite_path)
@onready var dim_overlay: CanvasItem = get_node_or_null(dim_overlay_path)

var player_nearby: bool = false
var player_ref: Node2D = null
var is_dialog_playing: bool = false
var fade_tween: Tween


func _ready() -> void:
	if interaction_hint:
		interaction_hint.visible = false
	
	# Terapkan kondisi awal efek dim hanya jika node efek tersedia
	if door_sprite:
		door_sprite.modulate.a = idle_door_alpha
	if dim_overlay:
		dim_overlay.modulate.a = 0.0
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not player_nearby or is_dialog_playing:
		return
	if not event.is_action_pressed("interact"):
		return
	
	# 🔒 CEK GATE: progress cerita
	if GameState.current_stage < required_stage:
		_play_locked_dialog()
		return
	
	# 🔒 CEK GATE: wajib APD
	if require_apd and not Global.has_apd:
		_play_locked_dialog()
		return
	
	# 🚪 PROSES PINDAH SCENE
	if target_scene_path == "":
		push_warning("InteractableDoor: target_scene_path belum di-set pada " + name)
		return
	
	player_nearby = false
	if interaction_hint:
		interaction_hint.visible = false
	
	Global.spawn_point = target_spawn
	
	if reset_last_position_on_enter:
		Global.player_last_position = Vector2.ZERO
		Global.player_last_flip = false
	
	if sfx_player:
		sfx_player.play()
	
	# 🔥 Hanya update stage jika diset 'True' DAN stage pemain masih di bawah target
	if change_stage_on_enter and GameState.current_stage < next_stage:
		GameState.current_stage = next_stage
	
	TransitionScreen.transition_to_scene(target_scene_path)


func _play_locked_dialog() -> void:
	is_dialog_playing = true
	await PlayerGate.play_locked_dialog(player_ref, locked_dialog_path)
	is_dialog_playing = false


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = true
		player_ref = body
		if interaction_hint:
			interaction_hint.visible = true
		_animate_environment(near_door_alpha, near_overlay_alpha)


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_nearby = false
		player_ref = null
		if interaction_hint:
			interaction_hint.visible = false
		_animate_environment(idle_door_alpha, 0.0)


func _animate_environment(door_alpha: float, overlay_alpha: float) -> void:
	if not door_sprite and not dim_overlay:
		return
	
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween().set_parallel(true)
	fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if door_sprite:
		fade_tween.tween_property(door_sprite, "modulate:a", door_alpha, 0.5)
	if dim_overlay:
		fade_tween.tween_property(dim_overlay, "modulate:a", overlay_alpha, 0.5)
