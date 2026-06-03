extends CanvasLayer

@onready var anim_player = $AnimationPlayer
@onready var color_rect = $ColorRect
@onready var clock_loading = $ClockLoading

# Track whether the game is currently switching scenes
var is_loading: bool = false
# Adjust this to make the clock spin faster or slower
var spin_speed: float = 5.0 

func _ready() -> void:
	# Keep the clock hidden when the game first starts up
	clock_loading.visible = false

func _process(delta: float) -> void:
	# If we are in a transition, continuously rotate the clock over time
	if is_loading:
		clock_loading.rotation += spin_speed * delta

func transition_to_scene(target_scene_path: String) -> void:
	# 1. Block clicks
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 2. Fade out the main menu
	anim_player.play("fade_to_black")
	await anim_player.animation_finished
	
	# 3. Show the clock and start the spinning logic
	clock_loading.visible = true
	is_loading = true
	
	# (If you are using an AnimatedSprite2D frame animation instead of rotation, uncomment below:)
	# clock_loading.play("ticking") 
	
	# Optional: Add a tiny artificial delay (e.g., 0.5s) if your scenes load too fast 
	# and you want players to actually see your cool clock animation!
	await get_tree().create_timer(1.5).timeout
	
	# 4. Change the scene behind the scenes
	get_tree().change_scene_to_file(target_scene_path)
	
	# 5. Stop the clock spinning and hide it
	is_loading = false
	clock_loading.visible = false
	
	# (If using AnimatedSprite2D:)
	# clock_loading.stop()
	
	# 6. Fade back into the new game scene
	anim_player.play("fade_to_normal")
	await anim_player.animation_finished
	
	# 7. Unblock clicks
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
