extends CharacterBody2D

const SPEED = 200.0

# --- BARU: Menyimpan referensi objek yang bisa diajak interaksi di dekat player ---
var nearby_interactable = null 

@onready var animated_sprite = $AnimatedSprite2D

# --- BARU: Daftarkan player ke group saat game dimulai ---
func _ready():
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction: -1, 0, 1
	var direction := Input.get_axis("move_left", "move_right")
	
	# flip the sprite 
	if direction > 0:
		animated_sprite.flip_h = true
	elif direction < 0:
		animated_sprite.flip_h = false
	
	# Play animations
	if direction == 0:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("walking")
	
	# apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	# --- BARU: Deteksi input tombol interaksi ---
	# Memastikan tombol ditekan DAN ada objek interaktif di dekat player
	if Input.is_action_just_pressed("interact") and nearby_interactable != null:
		nearby_interactable.interact()
