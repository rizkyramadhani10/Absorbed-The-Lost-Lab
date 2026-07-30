extends Area2D

# --- REFERENSI NODE INTERNAL ---
@onready var interact_label: Node = $Label if has_node("Label") else null
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

# --- VARIABEL RUNTIME ---
var player_ref: Node2D = null
var is_collected: bool = false

func _ready() -> void:
	# Cek apakah kayu sudah diambil sebelumnya
	if Global.has_wood == true:
		if collision_shape:
			collision_shape.disabled = true
		queue_free()
		return
	
	# Hubungkan sinyal area untuk mendeteksi player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	show_interact_prompt(false)

# --- PENANGANAN AREA / PLAYER DETEKSI ---
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_ref = body
		body.nearby_interactable = self
		show_interact_prompt(true)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_ref = null
		if body.nearby_interactable == self:
			body.nearby_interactable = null
		show_interact_prompt(false)

func show_interact_prompt(show: bool) -> void:
	if interact_label:
		interact_label.visible = show

# --- LOGIKA UTAMA INTERAKSI ---
func interact() -> void:
	# Cek apakah sudah diambil
	if is_collected:
		return
	
	# Cek apakah player masih di dekat
	if player_ref == null:
		return
	
	# Ambil kayu
	is_collected = true
	Global.has_wood = true
	print("Kayu berhasil diambil!")
	
	# Sembunyikan prompt
	show_interact_prompt(false)
	
	# Hapus objek dari scene
	if collision_shape:
		collision_shape.disabled = true
	queue_free()
