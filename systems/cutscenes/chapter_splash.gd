extends CanvasLayer

@onready var background = $ColorRect
@onready var chapter_label = $ColorRect/RichTextLabel

# Dictionary untuk memetakan Stage mana saja yang memicu Splash Screen
var chapter_milestones = {
	GameState.StoryStage.POST_SHOWER: "CHAPTER 1",
	GameState.StoryStage.REACHED_OUTSIDE: "CHAPTER 2",
	GameState.StoryStage.BACK_TO_LAB: "CHAPTER 3"
}

func _ready() -> void:
	visible = false
	GameState.stage_changed.connect(_on_stage_changed)

func _on_stage_changed(new_stage: GameState.StoryStage) -> void:
	# Cek apakah stage baru ini ada di dalam dictionary milestone kita
	if chapter_milestones.has(new_stage):
		# Jika ada, ambil teks chapter-nya dan tampilkan
		show_chapter(chapter_milestones[new_stage])
	# Jika tidak ada (misal: POST_SHOWER, FOUND_WOOD), abaikan saja.

func show_chapter(chapter_text: String) -> void:
	chapter_label.text = chapter_text
	visible = true
	
	background.modulate.a = 0.0
	chapter_label.modulate.a = 0.0
	
	var tween = create_tween()
	
	# 1. Fade IN
	# tween_property starts sequentially, and .parallel() attaches the next one to it
	tween.tween_property(background, "modulate:a", 1.0, 1.0)
	tween.parallel().tween_property(chapter_label, "modulate:a", 1.0, 1.0)
	
	# 2. Hold on screen
	# Automatically waits for step 1 to finish, then pauses for 5.0 seconds
	tween.tween_interval(1.0) 
	
	# 3. Fade OUT
	# Automatically waits for the 5.0 second interval to finish
	tween.tween_property(background, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(chapter_label, "modulate:a", 0.0, 1.0)
	
	# 4. Hide the node entirely
	tween.tween_callback(func(): visible = false)
