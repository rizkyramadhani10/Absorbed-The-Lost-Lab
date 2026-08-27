extends Area3D

# Export variabel agar bisa diisi teks objektifnya langsung lewat Inspector
@export var new_objective_text: String = "Temukan kunci pintu"
@export_enum("Sekali Pakai", "Bisa Berulang") var trigger_mode: int = 0

func _ready() -> void:
	# Hubungkan signal bawaan Area3D saat ada objek masuk
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Pastikan node Player memiliki Group bernama "player"
	if body.is_in_group("player"):
		# Update teks objective lewat Manager
		ObjectiveManager.update_objective(new_objective_text)
		
		# Jika tipe trigger sekali pakai, hapus node dari world
		if trigger_mode == 0:
			queue_free()
