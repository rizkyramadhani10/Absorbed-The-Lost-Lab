extends CanvasLayer

# --- REFERENSI NODE ---
@onready var background: Sprite2D = $Background
@onready var tool_button: Button = $Background/ToolButton
@onready var tool_icon: TextureRect = $Background/ToolButton/ToolIcon
@onready var wood_icon: Sprite2D = $Background/WoodSlot/WoodIcon
@onready var rope_icon: Sprite2D = $Background/RopeSlot/RopeIcon
@onready var stone_icon: Sprite2D = $Background/StoneSlot/StoneIcon
@onready var status_label: Label = $Background/StatusLabel
@onready var back_button: Button = $BackButton

# --- WARNA ---
var dark_color: Color = Color(0.3, 0.3, 0.3, 1.0)
var bright_color: Color = Color(1.0, 1.0, 1.0, 1.0)

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	tool_button.pressed.connect(_on_tool_button_pressed)
	tool_button.disabled = true  # Awalnya tidak bisa diklik
	
	# Set status bahan dari Global ke variabel permanen
	# Ini memastikan bahan yang sudah diambil tetap tercatat meskipun pindah scene
	_restore_material_status()
	
	update_ui()

func _restore_material_status():
	# Jika alat sudah dibuat, semua bahan dianggap sudah diambil
	if Global.has_hammer:
		# Pastikan semua bahan dianggap sudah diambil
		Global.has_wood = true
		Global.has_rope = true
		Global.has_stone = true
		return
	
	# Cek status bahan dari Global
	# Global.has_wood, Global.has_rope, Global.has_stone sudah diatur oleh script masing-masing bahan
	
	# Tapi jika bahan sudah diambil, kita harus memastikan tetap true
	# karena saat pindah scene, Global variables tetap mempertahankan nilainya
	pass

func update_ui():
	# Update Wood Icon
	if Global.has_wood:
		wood_icon.modulate = bright_color
	else:
		wood_icon.modulate = dark_color
	
	# Update Rope Icon
	if Global.has_rope:
		rope_icon.modulate = bright_color
	else:
		rope_icon.modulate = dark_color
	
	# Update Stone Icon
	if Global.has_stone:
		stone_icon.modulate = bright_color
	else:
		stone_icon.modulate = dark_color
	
	var all_collected = Global.has_wood and Global.has_rope and Global.has_stone
	
	# Update Tool Button
	if all_collected and not Global.has_hammer:
		tool_icon.modulate = bright_color
		tool_button.disabled = false
		status_label.visible = false
			
	elif Global.has_hammer:
		tool_icon.modulate = bright_color
		tool_button.disabled = true
		wood_icon.modulate = dark_color
		rope_icon.modulate = dark_color
		stone_icon.modulate = dark_color
		tool_icon.modulate = dark_color
		status_label.visible = true
	else:
		tool_icon.modulate = dark_color
		tool_button.disabled = true
		status_label.visible = false

func _on_tool_button_pressed():
	craft_hammer()

func craft_hammer():
	if Global.has_wood and Global.has_rope and Global.has_stone:
		# Reset bahan
		Global.has_wood = false
		Global.has_rope = false
		Global.has_stone = false
		Global.has_hammer = true
		
		# Simpan status bahwa bahan sudah diambil (untuk mencegah muncul kembali)
		Global.materials_collected = true
		
		print("Alat penghancur batu berhasil dibuat!")
		update_ui()

func _on_back_pressed():
	visible = false
	Global.is_tablet_open = false
	_enable_player_input(true)

func show_tablet():
	visible = true
	Global.is_tablet_open = true
	_enable_player_input(false)
	update_ui()

func hide_tablet():
	visible = false
	Global.is_tablet_open = false
	_enable_player_input(true)

# Fungsi untuk mengaktifkan/menonaktifkan input pemain
func _enable_player_input(enabled: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_input(enabled)
		player.set_physics_process(enabled)
		print("Player input ", "diaktifkan" if enabled else "dinonaktifkan")
