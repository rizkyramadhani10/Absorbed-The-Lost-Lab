extends CanvasLayer

# --- REFERENSI NODE CRAFTING ---
@onready var background: Sprite2D = $Background
@onready var tab_container: TabContainer = $Background/TabContainer
@onready var crafting_tab: Control = $Background/TabContainer/CraftingTab
@onready var knowledge_tab: Control = $Background/TabContainer/KnowledgeTab

# --- REFERENSI CRAFTING TAB ---
@onready var tool_button: Button = $Background/TabContainer/CraftingTab/ToolButton
@onready var tool_icon: TextureRect = $Background/TabContainer/CraftingTab/ToolButton/ToolIcon
@onready var wood_icon: Sprite2D = $Background/TabContainer/CraftingTab/WoodSlot/WoodIcon
@onready var rope_icon: Sprite2D = $Background/TabContainer/CraftingTab/RopeSlot/RopeIcon
@onready var stone_icon: Sprite2D = $Background/TabContainer/CraftingTab/StoneSlot/StoneIcon
@onready var status_label: Label = $Background/TabContainer/CraftingTab/StatusLabel
@onready var title_label: Label = $Background/TabContainer/CraftingTab/TitleLabel

# --- REFERENSI KNOWLEDGE TAB ---
@onready var knowledge_list: VBoxContainer = $Background/TabContainer/KnowledgeTab/ScrollContainer/KnowledgeList
@onready var knowledge_count_label: Label = $Background/TabContainer/KnowledgeTab/KnowledgeCountLabel
@onready var knowledge_progress: ProgressBar = $Background/TabContainer/KnowledgeTab/KnowledgeProgress

# --- REFERENSI BACK BUTTON ---
@onready var back_button: Button = $BackButton

# --- WARNA ---
var dark_color: Color = Color(0.3, 0.3, 0.3, 1.0)
var bright_color: Color = Color(1.0, 1.0, 1.0, 1.0)

# --- DATA PENGETAHUAN ---
var knowledge_data: Dictionary = {
	"incubator": {
		"name": "Incubator",
		"description": "Alat untuk menginkubasi sampel pada suhu terkontrol. Digunakan untuk pertumbuhan mikroorganisme."
	},
	"autoclave": {
		"name": "Autoclave",
		"description": "Alat sterilisasi menggunakan uap panas bertekanan tinggi. Membunuh mikroorganisme pada peralatan lab."
	},
	"microscope": {
		"name": "Microscope",
		"description": "Alat untuk mengamati objek yang sangat kecil. Digunakan untuk melihat sel dan mikroorganisme."
	},
	"spectrophotometer": {
		"name": "Spectrophotometer",
		"description": "Alat untuk mengukur intensitas cahaya yang diserap oleh sampel. Digunakan untuk analisis kuantitatif."
	},
	"sonicator": {
		"name": "Sonicator",
		"description": "Alat yang menggunakan gelombang suara untuk memecah sel atau mencampur sampel."
	},
	"ph_meter": {
		"name": "pH Meter",
		"description": "Alat untuk mengukur tingkat keasaman (pH) suatu larutan."
	},
	"laboratory_refrigerator": {
		"name": "Lab Refrigerator",
		"description": "Kulkas laboratorium untuk menyimpan sampel dan reagen pada suhu rendah."
	},
	"burette_cabinet": {
		"name": "Burette Cabinet",
		"description": "Lemari untuk menyimpan burette dan peralatan titrasi dengan aman."
	},
	"thermo_scientific": {
		"name": "Thermo Scientific",
		"description": "Peralatan laboratorium untuk berbagai analisis ilmiah dan pengukuran presisi."
	},
	"analytical_balance": {
		"name": "Analytical Balance",
		"description": "Neraca analitik untuk mengukur massa dengan ketelitian tinggi hingga 0.0001 gram."
	},
	"fume_hood": {
		"name": "Fume Hood",
		"description": "Lemari asam untuk melindungi pengguna dari uap berbahaya saat bekerja dengan bahan kimia."
	},
	"burette_clamp": {
		"name": "Burette Clamp",
		"description": "Penjepit untuk memasang burette pada statif saat melakukan titrasi."
	},
	"aquades_dispenser": {
		"name": "Aquades Dispenser",
		"description": "Alat untuk mendistribusikan air suling (aquades) dengan volume terkontrol."
	},
}

func _ready():
	# 🔥 DEBUG: Cek semua node
	_check_nodes()
	
	# Hubungkan signal dengan aman
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	else:
		print("ERROR: BackButton tidak ditemukan!")
	
	if tool_button:
		tool_button.pressed.connect(_on_tool_button_pressed)
		tool_button.disabled = true
	else:
		print("ERROR: ToolButton tidak ditemukan!")
	
	# Set status bahan dari Global ke variabel permanen
	_restore_material_status()
	
	# Update UI
	update_ui()
	_update_knowledge_tab()

func _check_nodes():
	print("=== CHECKING NODES ===")
	
	# Cek Background
	if background:
		print("✅ Background ditemukan")
	else:
		print("❌ Background TIDAK ditemukan!")
	
	# Cek TabContainer
	if tab_container:
		print("✅ TabContainer ditemukan")
	else:
		print("❌ TabContainer TIDAK ditemukan!")
	
	# Cek CraftingTab
	if crafting_tab:
		print("✅ CraftingTab ditemukan")
	else:
		print("❌ CraftingTab TIDAK ditemukan!")
	
	# Cek KnowledgeTab
	if knowledge_tab:
		print("✅ KnowledgeTab ditemukan")
	else:
		print("❌ KnowledgeTab TIDAK ditemukan!")
	
	# Cek ToolButton
	if tool_button:
		print("✅ ToolButton ditemukan")
	else:
		print("❌ ToolButton TIDAK ditemukan!")
	
	# Cek BackButton
	if back_button:
		print("✅ BackButton ditemukan")
	else:
		print("❌ BackButton TIDAK ditemukan!")
	
	# Cek Knowledge nodes
	if knowledge_list:
		print("✅ KnowledgeList ditemukan")
	else:
		print("❌ KnowledgeList TIDAK ditemukan!")
	
	if knowledge_count_label:
		print("✅ KnowledgeCountLabel ditemukan")
	else:
		print("❌ KnowledgeCountLabel TIDAK ditemukan!")
	
	if knowledge_progress:
		print("✅ KnowledgeProgress ditemukan")
	else:
		print("❌ KnowledgeProgress TIDAK ditemukan!")
	
	print("=== END CHECK ===")

func _restore_material_status():
	# Jika alat sudah dibuat, semua bahan dianggap sudah diambil
	if Global.has_hammer:
		Global.has_wood = true
		Global.has_rope = true
		Global.has_stone = true
		return

func update_ui():
	# Pastikan semua node ada sebelum diakses
	if not wood_icon or not rope_icon or not stone_icon:
		return
	
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
	if tool_button and tool_icon and status_label:
		if all_collected and not Global.has_hammer:
			tool_icon.modulate = bright_color
			tool_button.disabled = false
			status_label.visible = false
				
		elif Global.has_hammer:
			tool_icon.modulate = bright_color
			tool_button.disabled = true
			if wood_icon: wood_icon.modulate = dark_color
			if rope_icon: rope_icon.modulate = dark_color
			if stone_icon: stone_icon.modulate = dark_color
			tool_icon.modulate = dark_color
			status_label.visible = true
		else:
			tool_icon.modulate = dark_color
			tool_button.disabled = true
			status_label.visible = false

func _update_knowledge_tab():
	# Pastikan node ada
	if not knowledge_count_label or not knowledge_list:
		return
	
	# Update jumlah pengetahuan
	var collected = Global.get_knowledge_count()
	var total = Global.get_total_knowledge()
	knowledge_count_label.text = "Pengetahuan: " + str(collected) + "/" + str(total)
	
	# Update progress bar
	if knowledge_progress:
		knowledge_progress.max_value = total
		knowledge_progress.value = collected
	
	# Bersihkan list lama
	for child in knowledge_list.get_children():
		child.queue_free()
	
	# Jika tidak ada pengetahuan yang terbuka, tampilkan pesan
	if collected == 0:
		var empty_label = Label.new()
		empty_label.text = "Belum ada pengetahuan yang terbuka.\nInteraksilah dengan alat-alat di lab untuk membuka pengetahuan."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 25)
		empty_label.add_theme_color_override("font_color", Color(1, 1, 1, 1.0))
		knowledge_list.add_child(empty_label)
		return
	
	# Tambahkan item pengetahuan yang sudah terbuka
	for key in Global.knowledge_unlocked:
		if Global.knowledge_unlocked[key]:
			# Cek apakah ada data untuk key ini
			if knowledge_data.has(key):
				var item = _create_knowledge_item(key)
				knowledge_list.add_child(item)
			else:
				# Jika key tidak ada di knowledge_data, buat dengan nama default
				print("WARNING: Key '", key, "' tidak ditemukan di knowledge_data! Membuat item default.")
				var default_data = {
					"name": key.capitalize().replace("_", " "),
					"description": "Pengetahuan tentang " + key.capitalize().replace("_", " ")
				}
				var item = _create_knowledge_item_from_data(key, default_data)
				knowledge_list.add_child(item)

func _create_knowledge_item(key: String) -> Control:
	var data = knowledge_data[key]
	return _create_knowledge_item_from_data(key, data)

func _create_knowledge_item_from_data(key: String, data: Dictionary) -> Control:
	var item = Panel.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.custom_minimum_size = Vector2(0, 140)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.3, 0.4, 1.0)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	item.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 12)
	item.add_child(hbox)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(44, 44)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	var placeholder = StyleBoxFlat.new()
	placeholder.bg_color = Color(0.2, 0.4, 0.7, 1.0)
	placeholder.corner_radius_top_left = 4
	placeholder.corner_radius_top_right = 4
	placeholder.corner_radius_bottom_left = 4
	placeholder.corner_radius_bottom_right = 4
	icon.add_theme_stylebox_override("panel", placeholder)
	hbox.add_child(icon)
	
	var text_container = VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_container)
	
	var name_label = Label.new()
	name_label.text = data["name"]
	name_label.add_theme_font_size_override("font_size", 30)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = data["description"]
	desc_label.add_theme_font_size_override("font_size", 25)
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.custom_minimum_size = Vector2(750, 30)
	text_container.add_child(desc_label)
	
	return item

func _on_tool_button_pressed():
	craft_hammer()

func craft_hammer():
	if Global.has_wood and Global.has_rope and Global.has_stone:
		Global.has_wood = false
		Global.has_rope = false
		Global.has_stone = false
		Global.has_hammer = true
		Global.materials_collected = true
		
		GameState.advance_to(GameState.StoryStage.MADE_AXE)
		
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
	_update_knowledge_tab()
	update_ui()

func hide_tablet():
	visible = false
	Global.is_tablet_open = false
	_enable_player_input(true)

func _enable_player_input(enabled: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_input(enabled)
		player.set_physics_process(enabled)
		print("Player input ", "diaktifkan" if enabled else "dinonaktifkan")
