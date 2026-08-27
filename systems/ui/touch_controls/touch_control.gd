extends CanvasLayer

signal interact_pressed
signal interact_released

@onready var tablet_ui: CanvasLayer = $TabletUI
@onready var open_tablet_btn: TouchScreenButton = $Tablet/OpenTablet

func _ready():
	if open_tablet_btn:
		open_tablet_btn.pressed.connect(_on_open_tablet_pressed)
	else:
		print("ERROR: Tombol OpenTablet tidak ditemukan!")
	
	# Cari dan hubungkan tombol interaksi
	var interact_btn = find_child("TouchScreenButton", true, false)
	if interact_btn:
		interact_btn.pressed.connect(_emit_interact_pressed)
		interact_btn.released.connect(_emit_interact_released)
		print("Tombol interaksi ditemukan dan dihubungkan!")
	else:
		print("ERROR: Tombol interaksi tidak ditemukan!")
	
	# Pastikan TabletUI tersembunyi di awal
	if tablet_ui:
		tablet_ui.visible = false
		print("TabletUI ditemukan dan disembunyikan")
	else:
		print("ERROR: TabletUI tidak ditemukan di TouchControl!")

func _emit_interact_pressed():
	interact_pressed.emit()
	print("Interact pressed!")

func _emit_interact_released():
	interact_released.emit()
	print("Interact released!")

func _on_open_tablet_pressed():
	if tablet_ui:
		# Toggle visibility
		tablet_ui.visible = !tablet_ui.visible
		print("Tablet visibility toggled: ", tablet_ui.visible)
		
		# Update Global status
		Global.is_tablet_open = tablet_ui.visible
		
		# Jika tablet menjadi visible, refresh UI
		if tablet_ui.visible and tablet_ui.has_method("show_tablet"):
			tablet_ui.show_tablet()
		else:
			# Jika tablet ditutup, aktifkan kembali input pemain
			_enable_player_input(true)
	else:
		print("ERROR: TabletUI tidak tersedia!")

# Fungsi untuk mengaktifkan/menonaktifkan input pemain
func _enable_player_input(enabled: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_input(enabled)
		player.set_physics_process(enabled)
		print("Player input ", "diaktifkan" if enabled else "dinonaktifkan")
