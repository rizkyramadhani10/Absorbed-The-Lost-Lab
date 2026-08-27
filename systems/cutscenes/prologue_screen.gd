extends Control

@onready var video_player = $VideoStreamPlayer
@onready var skip_hint = $SkipHintLabel

var tap_count = 0
var fade_tween: Tween

# Add a variable to track the exact millisecond of the last tap
var last_tap_time: int = 0 

# Guard agar prologue hanya selesai SEKALI (video end & double-tap tidak dobel)
var is_finished: bool = false
var reset_timer: SceneTreeTimer

func _ready():
	skip_hint.modulate.a = 0.0
	skip_hint.show() 
	
	video_player.finished.connect(_on_video_finished)
	video_player.play()

func _input(event):
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		# Get the current time in milliseconds
		var current_time = Time.get_ticks_msec()
		
		# Only process the tap if at least 100 milliseconds have passed since the last one
		if current_time - last_tap_time > 100:
			last_tap_time = current_time
			_handle_tap()

func _handle_tap():
	if is_finished:
		return
		
	tap_count += 1
	
	if tap_count == 1:
		fade_in_hint()
		_start_reset_timer()
	elif tap_count >= 2:
		finish_prologue()

func fade_in_hint():
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		
	fade_tween = create_tween()
	fade_tween.tween_property(skip_hint, "modulate:a", 1.0, 0.3)

func _start_reset_timer():
	# Jangan tumpuk timer baru setiap tap — cukup satu yang berjalan
	if reset_timer != null:
		return
	reset_timer = get_tree().create_timer(3.0)
	reset_timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	reset_timer = null
	if tap_count == 1:
		fade_out_hint()
		tap_count = 0 

func fade_out_hint():
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		
	fade_tween = create_tween()
	fade_tween.tween_property(skip_hint, "modulate:a", 0.0, 0.5)

func _on_video_finished():
	finish_prologue()

func finish_prologue():
	if is_finished:
		return
	is_finished = true
	video_player.stop()
	TransitionScreen.transition_to_scene("res://levels/thirdLab(TimeMachine)/game.tscn")
