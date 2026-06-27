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

func _ready():
	add_to_group("player")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# 🔥 FIX 1: Sinkronisasi status APD saat scene dimuat ulang
	has_apd = Global.has_apd
	
	# Jika saat masuk scene player ternyata sudah pakai APD, langsung putar animasi APD
	if has_apd:
		animated_sprite.play("apdIdle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_interacting:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		_handle_interaction_input()
		_update_shadow() # Updates the shadow while interacting/stationary
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
	_handle_interaction_input()
	_update_shadow() # Updates the shadow during regular movement

func _handle_interaction_input():
	if Input.is_action_just_pressed("interact") and nearby_interactable != null:
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
			
			# 🔥 FIX 2: Simpan status pemakaian APD ke global agar permanen
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

# --- Dynamic Shadow Logic via Raycasting ---
func _update_shadow() -> void:
	if $ShadowRAY.get_collider() == self:
		$ShadowRAY.add_exception(self)
		
	if $ShadowRAY.is_colliding():
		$shadow.visible = true
		
		# 1. Menempelkan posisi Y bayangan tepat di atas permukaan tanah
		var ground_y: float = $ShadowRAY.get_collision_point().y
		$shadow.global_position.y = ground_y
		
		# 2. Menghitung total jarak dari Raycast sampai ke tanah
		var ray_start_y: float = $ShadowRAY.global_position.y
		var total_distance: float = ground_y - ray_start_y
		
		# Jarak dasar saat berdiri diam
		var standing_distance: float = 140.5
		var air_distance: float = max(0.0, total_distance - standing_distance)
		
		# 3. Hitung rasio perubahan (opacity & scale)
		var max_jump_distance: float = 150.0 
		var height_ratio: float = clamp(1.0 - (air_distance / max_jump_distance), 0.0, 1.0)
		
		# Terapkan transparansi
		$shadow.modulate.a = height_ratio
		
		# 🔥 FIX: Kalikan skala rasio dengan ukuran asli yang kamu buat di editor
		var shadow_scale: float = max(height_ratio, 0.5)
		$shadow.scale = base_shadow_scale * shadow_scale
	else:
		$shadow.visible = false
