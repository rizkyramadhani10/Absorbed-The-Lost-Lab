extends Control

# PENTING: Di Inspector, drag & drop semua 10 file resource pertanyaanmu ke array ini
@export var questions: Array[QuizQuestion] = []
@export var full_heart_texture: Texture2D
@export var empty_heart_texture: Texture2D

var current_question_index: int = 0
var current_health: int = 3
var current_question: QuizQuestion = null

@onready var health_hearts = [$HealthDisplay/Heart1, $HealthDisplay/Heart2, $HealthDisplay/Heart3]
@onready var question_display = $QuestionDisplay
@onready var answer_buttons = [$OptionsContainer/AnswerButtonA, $OptionsContainer/AnswerButtonB, $OptionsContainer/AnswerButtonC, $OptionsContainer/AnswerButtonD]
@onready var feedback_display = $FeedbackDisplay
@onready var results_panel = $ResultsPanel
@onready var result_label = $ResultsPanel/ResultLabel

signal quiz_finished(passed: bool)

func _ready():
	visible = false
	results_panel.visible = false
	feedback_display.visible = false
	for button in answer_buttons:
		button.pressed.connect(_on_answer_pressed.bind(answer_buttons.find(button)))

func start_quiz():
	print("DEBUG: Fungsi start_quiz() BERHASIL DIPANGGIL!")
	visible = true
	current_question_index = 0
	current_health = 3
	update_health_display()
	show_next_question()

# Tambahkan variabel ini di bagian atas script jika belum ada
var typing_speed: float = 0.03

func show_next_question():
	print("DEBUG: Jumlah soal yang terdeteksi di array = ", questions.size())
	if current_question_index < questions.size():
		current_question = questions[current_question_index]
		print("DEBUG: Soal saat ini = ", current_question.question_text)
		# === PERBAIKAN DI SINI ===
		# Kita panggil fungsi mengetik lokal agar teks muncul di dalam tablet
		type_local_question(current_question.question_text)
		
		# Update tombol pilihan jawaban
		for i in range(answer_buttons.size()):
			if i < current_question.choices.size():
				answer_buttons[i].text = current_question.choices[i]
				answer_buttons[i].visible = true
				answer_buttons[i].disabled = false # Pastikan tombol bisa diklik
			else:
				answer_buttons[i].visible = false
	else:
		finish_quiz(true) # Lulus jika semua soal terjawab

# === FUNGSI BARU UNTUK MENGETIK DI DALAM TABLET ===
func type_local_question(text_to_type: String):
	if question_display:
		question_display.text = text_to_type
		question_display.visible_characters = 0
		
		# Loop untuk memunculkan huruf satu per satu
		while question_display.visible_characters < text_to_type.length():
			question_display.visible_characters += 1
			await get_tree().create_timer(typing_speed).timeout

func _on_answer_pressed(choice_index: int):
	# Menonaktifkan tombol sementara selama feedback
	for button in answer_buttons: button.disabled = true
	
	if choice_index == current_question.correct_choice_index:
		feedback_display.text = "Benar!"
		feedback_display.modulate = Color.GREEN
	else:
		feedback_display.text = "Salah!"
		feedback_display.modulate = Color.RED
		current_health -= 1
		update_health_display()
	
	feedback_display.visible = true
	await get_tree().create_timer(1.0).timeout # Feedback timer
	feedback_display.visible = false
	
	for button in answer_buttons: button.disabled = false
	
	if current_health > 0:
		current_question_index += 1
		show_next_question()
	else:
		finish_quiz(false) # Gagal jika nyawa habis

func update_health_display():
	for i in range(health_hearts.size()):
		if i < current_health:
			health_hearts[i].texture = full_heart_texture
		else:
			health_hearts[i].texture = empty_heart_texture

func finish_quiz(passed: bool):
	results_panel.visible = true
	if passed:
		result_label.text = "Selamat! Anda lulus kuis."
		result_label.modulate = Color.GREEN
	else:
		result_label.text = "Maaf, Anda gagal. Silakan coba lagi."
		result_label.modulate = Color.RED
	quiz_finished.emit(passed)
