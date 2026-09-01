extends Control

@export var questions: Array[QuizQuestion] = []
@export var full_heart_texture: Texture2D
@export var empty_heart_texture: Texture2D

var current_question_index: int = 0
var current_health: int = 3
var current_question: QuizQuestion = null
var typing_speed: float = 0.03
var type_tween: Tween

@onready var health_hearts = [$HealthDisplay/Heart1, $HealthDisplay/Heart2, $HealthDisplay/Heart3]
@onready var question_display = $QuestionDisplay
@onready var answer_buttons = [$OptionsContainer/AnswerButtonA, $OptionsContainer/AnswerButtonB, $OptionsContainer/AnswerButtonC, $OptionsContainer/AnswerButtonD]
@onready var results_panel = $ResultsPanel
@onready var result_label = $ResultsPanel/ResultLabel

@onready var health_display_container = $HealthDisplay
@onready var options_container = $OptionsContainer
@onready var feedback_panel = $FeedbackPanel
@onready var feedback_display = $FeedbackPanel/FeedbackDisplay 

signal quiz_finished(passed: bool)

func _ready():
	visible = false
	results_panel.visible = false
	if feedback_panel: feedback_panel.visible = false
		
	for button in answer_buttons:
		button.pressed.connect(_on_answer_pressed.bind(answer_buttons.find(button)))

func start_quiz():
	visible = true
	current_question_index = 0
	current_health = 3
	
	if question_display: question_display.visible = true
	if options_container: options_container.visible = true
	if health_display_container: health_display_container.visible = true
	if results_panel: results_panel.visible = false
		
	update_health_display()
	show_next_question()

func show_next_question():
	if current_question_index < questions.size():
		current_question = questions[current_question_index]
		type_local_question(current_question.question_text)
		
		for i in range(answer_buttons.size()):
			if i < current_question.choices.size():
				answer_buttons[i].text = current_question.choices[i]
				answer_buttons[i].visible = true
				answer_buttons[i].disabled = false 
			else:
				answer_buttons[i].visible = false
	else:
		finish_quiz(true)

func type_local_question(text_to_type: String):
	if question_display:
		# Hentikan tween ketik sebelumnya agar tidak ada dua loop yang saling
		# merebut visible_characters saat pemain menekan jawaban dengan cepat
		if type_tween and type_tween.is_valid():
			type_tween.kill()
		
		question_display.text = text_to_type
		question_display.visible_characters = 0
		
		# Satu tween untuk seluruh teks (bukan Timer baru per karakter)
		var total_chars := text_to_type.length()
		type_tween = create_tween()
		type_tween.tween_method(
			func(value: float): question_display.visible_characters = int(value),
			0.0,
			float(total_chars),
			total_chars * typing_speed
		)

func _on_answer_pressed(choice_index: int):
	for button in answer_buttons: button.disabled = true
	
	if choice_index == current_question.correct_choice_index:
		feedback_display.text = "Benar!"
		feedback_display.modulate = Color.GREEN
	else:
		feedback_display.text = "Salah!"
		feedback_display.modulate = Color.RED
		current_health -= 1
		update_health_display()
	
	if feedback_panel: feedback_panel.visible = true
	await get_tree().create_timer(1.0).timeout 
	if feedback_panel: feedback_panel.visible = false
	
	for button in answer_buttons: button.disabled = false
	
	if current_health > 0:
		current_question_index += 1
		show_next_question()
	else:
		finish_quiz(false)

func update_health_display():
	for i in range(health_hearts.size()):
		if i < current_health:
			health_hearts[i].texture = full_heart_texture
		else:
			health_hearts[i].texture = empty_heart_texture

func finish_quiz(passed: bool):
	if passed:
		# Sembunyikan semua text kuis biar layarnya bersih menampung sertifikat background
		if question_display: question_display.visible = false
		if options_container: options_container.visible = false
		if health_display_container: health_display_container.visible = false
		if results_panel: results_panel.visible = false
		get_tree().call_group("portal_waktu", "aktifkan_portal")
	else:
		if results_panel: results_panel.visible = true
		if result_label:
			result_label.text = "Maaf, Anda gagal. Silakan coba lagi."
			result_label.modulate = Color.RED
			
	# Kirim sinyal ke tablet_view
	quiz_finished.emit(passed)
