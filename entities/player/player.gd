extends CharacterBody2D

const SPEED = 200.0
const RUN_SPEED = 500.0 # 🔥 Kecepatan saat lari (bisa disesuaikan)
const TIME_TO_RUN = 1.1 # 🔥 Waktu (detik) tombol ditahan sebelum mulai lari

# --- Menyimpan referensi objek yang bisa diajak interaksi di dekat player ---
var nearby_interactable = null 
var interacting_object = null 

# --- Status Kostum & Status Interaksi ---
var has_apd: bool = false
var is_interacting: bool = false
var pending_apd_suit: bool = false 
var is_holding_interact: bool = false 

# --- Variabel untuk mekanik lari ---
var walk_timer: float = 0.0
var is_running: bool = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var base_shadow_scale = $shadow.scale
@onready var walk_sfx = $WalkSFX 
@onready var shadow_ray: RayCast2D = $ShadowRAY
@onready var shadow = $shadow

func _ready():
	add_to_group("player")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Pengecualian raycast cukup didaftarkan sekali, bukan setiap frame
	shadow_ray.add_exception(self)
	
	# FIX 1: Sinkronisasi status APD saat scene dimuat ulang
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
	
	# --- LOGIKA ARAH HADAP ---
	if direction > 0:
		animated_sprite.flip_h = true
	elif direction < 0:
		animated_sprite.flip_h = false
	
	# --- LOGIKA TIMER LARI & ANIMASI ---
	if direction == 0:
		# Reset timer dan status lari kalau player berhenti
		walk_timer = 0.0
		is_running = false
		
		if has_apd:
			animated_sprite.play("apdIdle")
		else:
			animated_sprite.play("idle")
	else:
		# Tambah timer selama tombol arah ditahan
		walk_timer += delta
		if walk_timer >= TIME_TO_RUN:
			is_running = true
			
		# Mainkan animasi jalan atau lari berdasarkan status is_running & has_apd
		if has_apd:
			if is_running:
				animated_sprite.play("apdRun")
			else:
				animated_sprite.play("apdWalking")
		else:
			if is_running:
				animated_sprite.play("run")
			else:
				animated_sprite.play("walking")
	
	# --- TERAPKAN KECEPATAN (Jalan vs Lari) ---
	var current_speed = RUN_SPEED if is_running else SPEED
	
	if direction:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)

	move_and_slide()
	
	# --- LOGIKA SFX LANGKAH KAKI ---
	if direction != 0 and is_on_floor():
		if not walk_sfx.playing:
			walk_sfx.play()
		# Bikin efek suara langkah jadi lebih cepat pas lagi lari
		walk_sfx.pitch_scale = 1.3 if is_running else 1.0
	else:
		if walk_sfx.playing:
			walk_sfx.stop()

	_handle_interaction_input()
	_update_shadow() 

func _handle_interaction_input():
	# CEK: Jika tablet terbuka, jangan proses interaksi sama sekali
	if Global.is_tablet_open:
		return
	
	# Deteksi tombol interaksi ditekan (Keyboard/Gamepad)
	if Input.is_action_just_pressed("interact"):
		_on_interact_pressed()
	
	# Deteksi tombol interaksi dilepas (Keyboard/Gamepad)
	if Input.is_action_just_released("interact"):
		_on_interact_released()

# --- FUNGSI INTERAKSI DARI TOUCH CONTROL & KEYBOARD ---
func _on_interact_pressed():
	if Global.is_tablet_open:
		return
	
	if nearby_interactable != null:
		var target = nearby_interactable
		
		# Cek apakah objek memiliki fungsi interact()
		if target.has_method("interact"):
			var has_release = target.has_method("interact_release")
			
			is_holding_interact = true
			
			# Panggil animasi interaksi dan eksekusi target.interact()
			_do_normal_interaction()
			
			# Jika objek tidak membutuhkan event "dilepas" (hold), langsung set false
			if not has_release:
				is_holding_interact = false

func _on_interact_released():
	# Proses pelepasan tombol interaksi
	if is_holding_interact and nearby_interactable != null:
		if nearby_interactable.has_method("interact_release"):
			nearby_interactable.interact_release()
	is_holding_interact = false

func _do_normal_interaction():
	# Fungsi utama yang menangani animasi dan memicu aksi objek
	if nearby_interactable != null and not is_interacting:
		# SIMPAN POSISI & ARAH HADAP SEBELUM INTERAKSI
		Global.player_last_position = self.global_position
		Global.player_last_flip = animated_sprite.flip_h
		
		is_interacting = true
		interacting_object = nearby_interactable 
		
		if has_apd:
			animated_sprite.play("apdInteract")
		else:
			animated_sprite.play("interact")
			
		# Eksekusi aksi objek HANYA SATU KALI di sini
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
	if shadow_ray.is_colliding():
		shadow.visible = true
		var ground_y: float = shadow_ray.get_collision_point().y
		shadow.global_position.y = ground_y
		
		var ray_start_y: float = shadow_ray.global_position.y
		var total_distance: float = ground_y - ray_start_y
		
		var standing_distance: float = 140.5
		var air_distance: float = max(0.0, total_distance - standing_distance)
		
		var max_jump_distance: float = 150.0 
		var height_ratio: float = clamp(1.0 - (air_distance / max_jump_distance), 0.0, 1.0)
		
		shadow.modulate.a = height_ratio
		var shadow_scale: float = max(height_ratio, 0.5)
		shadow.scale = base_shadow_scale * shadow_scale
	else:
		shadow.visible = false

func kembalikan_posisi_setelah_minigame() -> void:
	if Global.spawn_point != "":
		return 

	if Global.player_last_position != Vector2.ZERO:
		global_position = Global.player_last_position
		
		animated_sprite.flip_h = Global.player_last_flip
		
		print("PLAYER SCRIPT: Posisi & Arah hadap dipulihkan.")
		
		Global.player_last_position = Vector2.ZERO
		Global.player_last_flip = false
