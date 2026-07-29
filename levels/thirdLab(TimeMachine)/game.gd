extends Node2D

@onready var player = $Player
@onready var blink_effect = $BlinkBlurEffect        # Tarik node CanvasLayer efekmu
@onready var anim_player = $BlinkBlurEffect/AnimationPlayer # Tarik node AnimationPlayer-nya

func _ready() -> void:
	print("Spawn point yang diterima dari Global di Third Lab: ", Global.spawn_point)
	
	add_to_group("game")
	
	# 🔥 Pindahkan posisi player secara instan saat scene dimuat (Tanpa delay)
	setup_third_lab_spawns()
	
	# 🎬 CEK APAKAH PERTAMA KALI BERMAIN
	if TransitionScreen.is_first_time_play:
		# 1. Kunci pergerakan player agar tidak bisa jalan saat pingsan/kedip-kedip
		if player:
			player.set_physics_process(false)
			player.set_process_unhandled_input(false)
		
		# 2. Jalankan animasi mata berkedip & terbangun
		anim_player.play("wake_up")
		
		# Ubah status global menjadi false agar tidak keulang jika restart map/level
		TransitionScreen.is_first_time_play = false
	else:
		# Jika bukan pertama kali main (misal ganti area lalu balik lagi), 
		# hapus efek kedipan agar layar langsung bersih semenjak awal masuk.
		if blink_effect:
			blink_effect.queue_free()

# Fungsi untuk mengatur posisi spawn Player secara aman dan instan di Third Lab
func setup_third_lab_spawns() -> void:
	if Global.spawn_point == "SpawnFromSecondLab":
		if has_node("SpawnFromSecondLab"):
			player.set_deferred("global_position", $SpawnFromSecondLab.global_position)
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromSecondLab!")
		else:
			print("ERROR di Third Lab: Marker 'SpawnFromSecondLab' tidak ditemukan di Scene Tree!")
			
	elif Global.spawn_point == "SpawnFromStorage":
		if has_node("SpawnFromStorage"):
			player.set_deferred("global_position", $SpawnFromStorage.global_position)
			print("Level: Player berhasil dipindahkan ke SpawnFromStorage!")
		else:
			print("ERROR: Marker 'SpawnFromStorage' tidak ditemukan di Scene Tree!")
			
	elif Global.spawn_point == "SpawnFromMeadow":
		if has_node("SpawnFromMeadow"):
			# Menggunakan set_deferred agar posisi diubah tepat di frame pertama tanpa delay visual
			player.set_deferred("global_position", $SpawnFromMeadow.global_position)
			print("Third Lab: Player berhasil dipindahkan ke SpawnFromMeadow!")
		else:
			print("ERROR di Meadow: Marker 'SpawnFromMeadow' tidak ditemukan di Scene Tree!")

# 🔓 HUBUNGKAN SIGNAL ANIMATION_FINISHED DARI ANIMATIONPLAYER KE SINI
# 🔓 HUBUNGKAN SIGNAL ANIMATION_FINISHED DARI ANIMATIONPLAYER KE SINI
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "wake_up":
		print("Animasi wake_up selesai. Memulai dialog awal...")
		
		# 1. Hapus efek kedipan
		if blink_effect:
			blink_effect.queue_free()
			
		# 2. Load resource dialog
		var dialogue_resource = load("res://dialogues/Dialogues/AllDialogues/dialog_01_awake.json.tres")
		
		# 3. Jalankan dialog lewat DialogPlayer milik Player
		if player and player.has_node("DialogPlayer"):
			var dp = player.get_node("DialogPlayer")
			
			# Assign resource dialog ke properti dialogue_data
			dp._dialog_data = dialogue_resource
			
			# Jalankan dialog
			dp.start()
			
			# Tunggu hingga dialog selesai (menggunakan signal dialog_ended)
			await dp.dialog_ended
		
		# 4. Kembalikan kontrol penuh ke player
		if player:
			player.set_physics_process(true)
			player.set_process_unhandled_input(true)
			
		print("Player sadar sepenuhnya dan siap bergerak!")
