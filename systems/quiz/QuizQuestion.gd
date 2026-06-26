extends Resource
class_name QuizQuestion

@export_multiline var question_text: String
@export var choices: Array[String] = []
@export var correct_choice_index: int # The index of the correct answer (0, 1, 2, or 3)
