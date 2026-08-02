extends CharacterBody2D

const SPEED = 200.0

# --- Menyimpan referensi objek yang bisa diajak interaksi di dekat player ---
var nearby_interactable = null 
var interacting_object = null 

# --- Status Kostum & Status Interaksi ---
var has_apd: bool = false
var is_interacting: bool = false
var pending_apd_suit: bool = false 

@onready var animated_sprite = $AnimatedSprite2D
@onready var base_shadow_scale = $shadow.scale
@onready var walk_sfx = $WalkSFX 

func _ready():
	add_to_group("player")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# 🔥 FIX 1: Sinkronisasi status APD saat scene dimuat ulang
	has_apd = Global.has_apd
	
	if has_apd:
		animated_sprite.play("apdIdle")
	
	call_deferred("kembalikan_posisi_setelah_minigame")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_interacting:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		_handle_interaction_input()
		_update_shadow() 
		
		if walk_sfx.playing:
			walk_sfx.stop()
		return 

	var direction := Input.get_axis("move_left", "move_right")
	
	if direction > 0:
		animated_sprite.flip_h = true
	elif direction < 0:
		animated_sprite.flip_h = false
	
	if direction == 0:
		if has_apd:
			animated_sprite.play("apdIdle")
		else:
			animated_sprite.play("idle")
	else:
		if has_apd:
			animated_sprite.play("apdWalking")
		else:
			animated_sprite.play("walking")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if direction != 0 and is_on_floor():
		if not walk_sfx.playing:
			walk_sfx.play()
	else:
		if walk_sfx.playing:
			walk_sfx.stop()

	_handle_interaction_input()
	_update_shadow() 

func _handle_interaction_input():
	if Input.is_action_just_pressed("interact") and nearby_interactable != null:
		# 🔥 SIMPAN POSISI & ARAH HADAP SEBELUM INTERAKSI
		Global.player_last_position = self.global_position
		Global.player_last_flip = animated_sprite.flip_h
		
		is_interacting = true
		interacting_object = nearby_interactable 
		
		if has_apd:
			animated_sprite.play("apdInteract")
		else:
			animated_sprite.play("interact")
			
		nearby_interactable.interact()

func wear_apd_suit():
	pending_apd_suit = true

func _on_animation_finished():
	if animated_sprite.animation == "interact":
		if pending_apd_suit and interacting_object and interacting_object.has_method("hide_suit"):
			interacting_object.hide_suit()
			
		if pending_apd_suit:
			pending_apd_suit = false
			has_apd = true
			Global.has_apd = true
			animated_sprite.play("apdIdle")
			is_interacting = false 
			
			var game = get_tree().get_first_node_in_group("game")
			if game and game.has_method("start_apd_monologue"):
				game.start_apd_monologue()
		else:
			is_interacting = false
			
		interacting_object = null
			
	elif animated_sprite.animation == "apdInteract":
		is_interacting = false
		interacting_object = null

func _update_shadow() -> void:
	if $ShadowRAY.get_collider() == self:
		$ShadowRAY.add_exception(self)
		
	if $ShadowRAY.is_colliding():
		$shadow.visible = true
		var ground_y: float = $ShadowRAY.get_collision_point().y
		$shadow.global_position.y = ground_y
		
		var ray_start_y: float = $ShadowRAY.global_position.y
		var total_distance: float = ground_y - ray_start_y
		
		var standing_distance: float = 140.5
		var air_distance: float = max(0.0, total_distance - standing_distance)
		
		var max_jump_distance: float = 150.0 
		var height_ratio: float = clamp(1.0 - (air_distance / max_jump_distance), 0.0, 1.0)
		
		$shadow.modulate.a = height_ratio
		var shadow_scale: float = max(height_ratio, 0.5)
		$shadow.scale = base_shadow_scale * shadow_scale
	else:
		$shadow.visible = false

func kembalikan_posisi_setelah_minigame() -> void:
	if Global.spawn_point != "":
		return 

	if Global.player_last_position != Vector2.ZERO:
		global_position = Global.player_last_position
		
		animated_sprite.flip_h = Global.player_last_flip
		
		print("PLAYER SCRIPT: Posisi & Arah hadap dipulihkan.")
		
		Global.player_last_position = Vector2.ZERO
		Global.player_last_flip = false
