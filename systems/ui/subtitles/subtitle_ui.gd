extends CanvasLayer

@onready var container = $MarginContainer
@onready var subtitle_label = $MarginContainer/PanelContainer/SubtitleText 
@onready var sfx_player = $AudioStreamPlayer 

const SFX_XENO = preload("res://assets/audio/sfx/speaking/xenoSpeaking.mp3")
const SFX_AI = preload("res://assets/audio/sfx/speaking/aiSpeaking.mp3")

var typing_speed: float = 0.0198
var subtitle_tween: Tween 
var _last_char_index: int = -1 
var _clean_text: String = "" # Menyimpan teks bersih (tanpa tag BBCode) khusus untuk hitungan audio

# Regex di-compile SEKALI saja, bukan setiap baris dialog
var _tag_regex: RegEx = RegEx.new()

func _ready():
	container.hide()
	_tag_regex.compile("\\[.*?\\]")

func show_typewriter_text(text_to_type: String, character_name: String = "xeno", _duration_after_typing: float = 2.5):
	if subtitle_tween and subtitle_tween.is_valid():
		subtitle_tween.kill()
	
	if text_to_type == "":
		container.hide()
		sfx_player.stop()
		return
		
	container.show()
	_last_char_index = -1
	
	# ==================== PERUBAHAN UNTUK BBCODE ====================
	# Gunakan regex yang sudah di-compile sekali di _ready()
	_clean_text = _tag_regex.sub(text_to_type, "", true)
	# ================================================================
	
	match character_name.to_lower():
		"xeno":
			sfx_player.stream = SFX_XENO
		"ai", "tablet", "tablet_ai":
			sfx_player.stream = SFX_AI
		_:
			sfx_player.stream = SFX_XENO 
	
	# Tetap masukkan teks mentah berkode ke RichTextLabel agar formatnya muncul
	subtitle_label.text = text_to_type
	subtitle_label.visible_characters = 0
	
	# PENTING: Hitung total durasi berdasarkan panjang teks BERSIH (tanpa tag)
	var total_characters = _clean_text.length()
	var total_typing_time = total_characters * typing_speed
	
	subtitle_tween = create_tween()
	subtitle_tween.tween_method(
		_on_character_typed,
		0.0,
		float(total_characters),
		total_typing_time
	)
	
	subtitle_tween.finished.connect(func(): 
		sfx_player.stop()
	)

func _on_character_typed(value: float):
	var current_char_count = int(value)
	subtitle_label.visible_characters = current_char_count
	
	if current_char_count > _last_char_index:
		_last_char_index = current_char_count
		
		if current_char_count > 0 and not sfx_player.playing:
			# Pengecekan spasi dialihkan ke _clean_text agar sinkron dengan huruf di layar
			if current_char_count <= _clean_text.length():
				var char_typed = _clean_text[current_char_count - 1]
				
				if char_typed != " " and char_typed != "\n":
					sfx_player.play()
