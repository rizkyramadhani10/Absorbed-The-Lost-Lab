@tool 
@icon("res://addons/sprouty_dialogs/editor/icons/nodes/dialog_box.svg")
class_name DialogBox
extends Control

# -----------------------------------------------------------------------------
# Sprouty Dialogs Dialog Box
# -----------------------------------------------------------------------------
## Node that displays dialogue text on screen. Provides basic functionality to
## displaying text with typing effect, character names, portraits, and options.
##
## You should not use this node directly to play a dialogue. You should use a
## [DialogPlayer] node to play dialogues, which will use a dialog box to
## display the dialog.
# -----------------------------------------------------------------------------

## Emitted when the dialog is started.
signal dialog_starts
## Emitted when the dialog ends typing.
signal dialog_typing_ends
## Emitted when the dialog is ended.
signal dialog_ends

## Emitted when the player press the continue button to continue the dialog tree 
signal continue_dialog
## Emitted when a meta tag is clicked in the dialog.
signal meta_clicked(meta: String)

## Emitted when the player selects an option.
signal option_selected(option_index: int)

## Typing speed of the dialog text in seconds.
@export var typing_speed: float = SproutyDialogsSettingsManager.get_setting("default_typing_speed")
## Maximum number of characters to be displayed in the dialog box.[br][br]
## The dialogue will be split according to this limit and displayed in parts
## if the [param split_dialog_by_max_characters] setting is active.
@export var max_characters: int = SproutyDialogsSettingsManager.get_setting("max_characters")
## If true, the dialog box will block input propagation to other nodes in the scene tree.[br][br]
## This is useful to prevent the player from interacting with other nodes while the dialog is active.[br]
@export var block_input_propagation: bool = true

@export_category("Dialog Box Components")
## [RichTextLabel] where dialogue will be displayed.[br][br]
## [color=tomato]This component is required to display the text in it.[/color]
@export var dialog_display: RichTextLabel:
	set(value):
		dialog_display = value
		if Engine.is_editor_hint():
			update_configuration_warnings()

## [RichTextLabel] where character name will be displayed.[br][br]
## [color=tomato]If you want to display the character name in the dialog box, 
## you need to set this property.[/color]
@export var name_display: RichTextLabel

## Visual indicator to indicate press for continue the dialogue (e.g. an arrow).
## [br][br][color=tomato]If you want to display a continue indicator in the
## dialog box,you need to set this property.[/color]
@export var continue_indicator: Control

## [Node] where the character portrait will be displayed (portrait parent).[br][br]
## [color=tomato]If you want to display the portrait in the dialog box, 
## you need to set this property.[/color]
@export var portrait_display: Node

@export_category("Options Components")
## [Container] where the options will be displayed in the dialog box.
## It is recommended a [VBoxContainer] or [GridContainer] to display the options.
## [color=tomato]This component is required to display the dialog options in it.[/color]
@export var options_container: Container

## [Node] that will be used as a template for the options in the dialog box.
## It should be a [DialogOption] node or another node that extends it.
## [br][br][color=tomato]This component is required to display the dialog options. [/color]
@export var option_template: DialogOption

## Timer to control the typing speed of the dialog.
var _type_timer: Timer

## Timer to control if the dialog can be skipped.
var _can_skip_timer: Timer

## Flag to control if the dialog can be skipped.
var _can_skip: bool = true

## Array to store the typing speed intervals for different parts of the dialog.
var _typing_speed_intervals: Array = []

## Flag to control if the dialog is completed.
var _display_completed: bool = false

## Array to store the dialog sentences.
var _sentences: Array[String] = []

## Index of the current sentence being displayed.
var _current_sentence: int = 0

## Current sentence lenght
var _sentence_lenght: int = 0

## Start index of the current sentence in the whole dialog (clean character count)
var _current_sentence_start_index: int = 0

## Flag to check if the dialog box is displaying a portrait.
var _is_displaying_portrait: bool = false

## Flag to check if the dialog box is displaying options.
var _is_displaying_options: bool = false

## Flag to check if the dialog box was already started.
var _is_started: bool = false

## Flag to check if the dialog is running
var _is_running: bool = false

# Flag to prevent the same touch from also being processed
# as an emulated mouse click.
var _touch_input_processed: bool = false


## Handle editor warnings
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if not dialog_display: # Check if the node is empty or invalid
		warnings.push_back(
			"A dialog display component must be provided to display the dialogues. "
			+ "Please assign a RichTextLabel node as dialog display in the inspector."
		)

	return warnings


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		# Set typing_speed here because reading the setting at variable declaration can return the original default instead of a user-modified value.
		# Assigning it in _enter_tree ensures we pick up the user's saved setting after the settings manager has initialized.
		# The settings manager may not be fully loaded or updated when the script is first parsed,
		# so performing this assignment when the node enters the scene tree guarantees the current (possibly user-changed) value is used.
		typing_speed = SproutyDialogsSettingsManager.get_setting("default_typing_speed")

		if typing_speed > 0.0:
			_type_timer = Timer.new()
			add_child(_type_timer)
			_type_timer.wait_time = typing_speed
			_type_timer.timeout.connect(_on_type_timer_timeout)

		_can_skip_timer = Timer.new()
		add_child(_can_skip_timer)
		_can_skip_timer.wait_time = SproutyDialogsSettingsManager.get_setting("can_skip_delay")
		_can_skip_timer.timeout.connect(func(): _can_skip = true)

		hide()


func _ready() -> void:
	## Set predefined components in default dialog box
	var default_dialog_path = "DialogPanel/MarginContainer/DialogContainer"

	if not dialog_display and get_node_or_null(default_dialog_path + "/DialogDisplay"):
		dialog_display = get_node(default_dialog_path + "/DialogDisplay")

	if not name_display and get_node_or_null(default_dialog_path + "/NameDisplay"):
		name_display = get_node(default_dialog_path + "/NameDisplay")

	if not continue_indicator and get_node_or_null(default_dialog_path + "/ContinueIndicator"):
		continue_indicator = get_node(default_dialog_path + "/ContinueIndicator")

	if not options_container and get_node_or_null("OptionsContainer"):
		options_container = get_node("OptionsContainer")

	if not option_template and get_node_or_null("OptionsContainer/DialogOption"):
		option_template = get_node("OptionsContainer/DialogOption")

	if not Engine.is_editor_hint():
		# Connect meta clicked signal to handle meta tags
		if not dialog_display:
			printerr(
				"[Sprouty Dialogs] Dialog display is not set. Please set the "
				+ "'dialog_display' property in the '"
				+ name
				+ "' Dialog Box on the inspector."
			)
			return

		if not dialog_display.is_connected("meta_clicked", _on_dialog_meta_clicked):
			dialog_display.meta_clicked.connect(_on_dialog_meta_clicked)

		dialog_display.bbcode_enabled = true

		if option_template:
			option_template = option_template.duplicate()

		if continue_indicator:
			continue_indicator.hide()

		if options_container:
			options_container.hide()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if not _is_running:
		return

	if _is_displaying_options:
		return

	# -------------------------------------------------------------------------
	# TOUCH SCREEN
	#
	# Handle touch FIRST so it does not also enter the normal
	# Input.is_action_just_pressed() block.
	# -------------------------------------------------------------------------
	if event is InputEventScreenTouch and event.pressed:

		_touch_input_processed = true

		# Clear the flag shortly after this touch so a later real
		# mouse click still works normally.
		get_tree().create_timer(0.15).timeout.connect(
			func():
				_touch_input_processed = false
		)

		# Touch while typing:
		# Use the ORIGINAL skip behavior.
		if not _display_completed and _can_skip:
			_skip_dialog_typing()

		# Touch after typing is complete:
		# Continue to the next sentence / dialog.
		elif _display_completed:

			if _current_sentence < _sentences.size() - 1:
				_current_sentence += 1
				_display_new_sentence(_sentences[_current_sentence])
			else:
				# Defer this so the new dialog starts only after
				# the current touch event has finished.
				call_deferred("_continue_dialog_from_touch")

		if block_input_propagation:
			get_viewport().set_input_as_handled()

		return

	# -------------------------------------------------------------------------
	# PREVENT EMULATED MOUSE CLICK
	#
	# If Godot converts the same phone touch into a mouse click,
	# ignore that mouse click so the next dialog does NOT receive
	# the same input and instantly skip its typing.
	# -------------------------------------------------------------------------
	if _touch_input_processed and event is InputEventMouseButton:
		if event.pressed:
			if block_input_propagation:
				get_viewport().set_input_as_handled()

			_touch_input_processed = false
			return

	# -------------------------------------------------------------------------
	# ORIGINAL INPUT
	#
	# Keyboard / mouse / controller behavior remains unchanged.
	# -------------------------------------------------------------------------
	if Input.is_action_just_pressed(
			SproutyDialogsSettingsManager.get_setting("continue_input_action")):

		if not _display_completed and _can_skip:
			_skip_dialog_typing()

		elif _display_completed:
			if _current_sentence < _sentences.size() - 1:
				_current_sentence += 1
				_display_new_sentence(_sentences[_current_sentence])
			else:
				continue_dialog.emit()

	if block_input_propagation:
		get_viewport().set_input_as_handled()


func _continue_dialog_from_touch() -> void:
	# Make absolutely sure the touch that opened the next dialog
	# cannot immediately affect the newly opened dialog.
	_touch_input_processed = false
	continue_dialog.emit()


## Play a dialog on dialog box
func play_dialog(character_name: String, dialog_data: Dictionary) -> void:
	if not _is_started:
		await _on_dialog_box_open()

	hide_options()

	if not visible:
		show()

	if name_display:
		name_display.text = character_name
		name_display.visible = character_name != ""

	var dialog: String = dialog_data.get("text", "")
	dialog_display.text = dialog

	_typing_speed_intervals = dialog_data.get("speed", [])
	_sort_typing_speed_intervals()

	_current_sentence = 0
	_sentences = []

	if dialog.is_empty():
		# If the dialog is empty, just display an empty sentence
		_sentences.append("")
	else:
		# Split the dialog by lines and characters if the settings are enabled
		var dialog_lines = _split_dialog_by_lines(dialog)

		for line in dialog_lines:
			var split_result = _split_dialog_by_characters(line)
			_sentences.append_array(split_result)

	# Start the dialog
	_is_started = true
	_is_running = true
	_display_completed = false

	_display_new_sentence(_sentences[_current_sentence])

	dialog_starts.emit()


## Pause the dialog
func pause_dialog() -> void:
	_is_running = false

	if _type_timer:
		_type_timer.paused = true


## Resume the dialog
func resume_dialog() -> void:
	_is_running = true

	if _type_timer:
		_type_timer.paused = false


## Stop the dialog
func stop_dialog(close_dialog: bool = false) -> void:
	dialog_ends.emit()

	_display_completed = false
	_current_sentence = 0
	_is_running = false
	_sentences = []

	if close_dialog:
		await _on_dialog_box_close()
		_is_started = false
	else:
		hide()


## Skip the dialog typing and show the full text
func _skip_dialog_typing() -> void:
	dialog_display.visible_characters = dialog_display.text.length()

	if _type_timer:
		_type_timer.stop()

	# Wait for the continue delay before allowing to skip again
	await get_tree().create_timer(
		SproutyDialogsSettingsManager.get_setting("skip_continue_delay")
	).timeout

	_can_skip = false
	_can_skip_timer.start()

	_on_display_completed()


#region === Virtual methods ====================================================

func _on_dialog_box_open() -> void:
	show()


func _on_dialog_box_close() -> void:
	hide()


func _on_options_displayed() -> void:
	if options_container:
		options_container.show()


func _on_options_hidden() -> void:
	if options_container:
		options_container.hide()

#endregion


#region === Display portrait ===================================================

func is_displaying_portrait() -> bool:
	return _is_displaying_portrait


func display_portrait(character_parent: Node, portrait_node: Node) -> void:
	if not portrait_display:
		printerr(
			"[Sprouty Dialogs] Cannot display the portrait in the dialog box. "
			+ "The dialog box doesn't have a portrait display."
		)

	if not portrait_display.has_node(NodePath(character_parent.name)):
		character_parent.add_child(portrait_node)
		portrait_display.add_child(character_parent)
	else:
		portrait_display.get_node(
			NodePath(character_parent.name)
		).add_child(portrait_node)

	_is_displaying_portrait = true

#endregion


#region === Display options ====================================================

func display_options(options: Array, disabled_flags: Array = []) -> void:
	_is_displaying_options = true

	if not options_container:
		printerr(
			"[SproutyDialogs] Dialog options container is not set. "
			+ "Please set the 'options_container' property in the '"
			+ name
			+ "' Dialog Box on the inspector."
		)
		return

	if not option_template:
		printerr(
			"[Sprouty Dialogs] Dialog option template is not set. "
			+ "Please set the 'option_template' property in the '"
			+ name
			+ "' Dialog Box on the inspector."
		)
		return

	# Clear previous options
	for child in options_container.get_children():
		child.queue_free()

	var selectable_index := 0

	for index in options.size():
		# Add new options
		var option_node = option_template.duplicate()
		option_node.set_text(options[index])

		var is_disabled: bool = (
			index < disabled_flags.size()
			and bool(disabled_flags[index])
		)

		option_node.disabled = is_disabled

		if not is_disabled:
			option_node.option_index = selectable_index
			selectable_index += 1
			option_node.option_selected.connect(option_selected.emit)

		options_container.add_child(option_node)
		option_node.show()

	_on_options_displayed()
	show()


func hide_options() -> void:
	if options_container:
		_on_options_hidden()

	_is_displaying_options = false

#endregion


#region === Split dialog =======================================================

func _split_dialog_by_lines(dialog: String) -> Array:
	if not SproutyDialogsSettingsManager.get_setting("new_line_as_new_dialog"):
		return [dialog]

	var lines = Array(dialog.split("\n"))

	if lines.size() == 0:
		return [dialog]

	var sentences = []
	var opened_tags = []
	var regex = RegEx.new()

	regex.compile("\\[.*?\\]")

	for line in lines:
		line = line.strip_edges()

		if line == "":
			continue

		# Add the opened tags from previous lines and update the opened tags
		sentences.append(
			_add_tags_to_sentence(
				line,
				opened_tags
			)
		)

		opened_tags = _get_opened_tags_from_sentence(
			line,
			opened_tags,
			regex
		)

	return sentences


func _split_dialog_by_characters(dialog: String) -> Array:
	if not SproutyDialogsSettingsManager.get_setting(
		"split_dialog_by_max_characters"
	) or max_characters > dialog.length():
		return [dialog]

	var words: Array = dialog.split(" ")
	var sentences: Array[String] = []

	var clean_sentence: String = ""
	var sentence: String = ""

	var opened_tags: Array = []
	var next_sentence_tags: Array = []

	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")

	var i = 0

	while i < words.size():
		var word = words[i]
		var clean_word = regex.sub(word, "", true)

		var aux_sentence = clean_sentence + " " + clean_word

		# If the sentence is short than the limit,
		# add the word to the sentence.
		if aux_sentence.length() < max_characters:
			sentence += " " + word
			clean_sentence += "" + clean_word

			opened_tags = _get_opened_tags_from_sentence(
				word,
				opened_tags,
				regex
			)

			i += 1
		else:
			sentence = _add_tags_to_sentence(
				sentence,
				next_sentence_tags
			)

			next_sentence_tags = opened_tags.duplicate()

			sentence = sentence.strip_edges()

			if sentence != "":
				sentences.append(sentence)

			clean_sentence = ""
			sentence = ""

	if sentence != "":
		# Add the last sentence to the sentences list
		sentence = _add_tags_to_sentence(
			sentence,
			next_sentence_tags
		)

		sentences.append(sentence)

	return sentences


func _get_opened_tags_from_sentence(
	sentence: String,
	opened_tags: Array,
	regex: RegEx
) -> Array:

	var tags = regex.search_all(sentence).map(
		func(tag):
			return tag.get_string()
	)

	for tag in tags:
		if tag.begins_with("[/"):
			var tag_begin = tag.replace("[/", "[").replace("]", "")

			var open_tag_index = opened_tags.find(
				func(open_tag):
					return open_tag.begins_with(tag_begin)
			)

			if open_tag_index:
				opened_tags.erase(opened_tags[open_tag_index])
		else:
			opened_tags.append(tag)

	return opened_tags


func _add_tags_to_sentence(sentence: String, tags: Array) -> String:
	var tags_string = ""

	for tag in tags:
		tags_string += tag

	sentence = tags_string + sentence

	return sentence

#endregion


#region === Display dialog =====================================================

func _display_new_sentence(sentence: String) -> void:
	dialog_display.text = sentence

	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")

	var clean_sentence = regex.sub(
		sentence,
		"",
		true
	)

	_sentence_lenght = clean_sentence.length()

	# Compute the global start index of the current sentence in the whole dialog
	var start_index: int = 0

	if _sentences.size() > 0 and _current_sentence > 0:
		var i: int = 0

		while i < _current_sentence:
			var prev_clean: String = regex.sub(
				_sentences[i],
				"",
				true
			)

			start_index += prev_clean.length()
			i += 1

	_current_sentence_start_index = start_index

	if typing_speed <= 0.0:
		dialog_display.visible_characters = dialog_display.text.length()
		_on_display_completed()
	else:
		# IMPORTANT:
		# Every new sentence/dialog starts typing from zero.
		dialog_display.visible_characters = 0

		if continue_indicator:
			continue_indicator.hide()

		_display_completed = false

		if _type_timer:
			_type_timer.stop()

			_type_timer.wait_time = _get_typing_speed_at(
				_current_sentence_start_index
			)

			_type_timer.start()


func _on_type_timer_timeout() -> void:
	if dialog_display.visible_characters < _sentence_lenght:
		dialog_display.visible_characters += 1

		# After showing a character, update the timer interval according
		# to the next character index so speed intervals take effect.
		if _type_timer:
			var next_index: int = (
				_current_sentence_start_index
				+ int(dialog_display.visible_characters)
			)

			var next_speed: float = _get_typing_speed_at(next_index)

			if _type_timer.wait_time != next_speed:
				_type_timer.wait_time = next_speed

	else:
		_type_timer.stop()
		_on_display_completed()


func _on_display_completed() -> void:
	if continue_indicator:
		continue_indicator.show()

	_display_completed = true
	dialog_typing_ends.emit()


func _on_dialog_ended() -> void:
	stop_dialog()


func _on_dialog_meta_clicked(meta: String) -> void:
	if SproutyDialogsSettingsManager.get_setting(
		"open_url_on_meta_tag_click"
	):
		OS.shell_open(meta)

	meta_clicked.emit(meta)

#endregion


#region === Typing speed ========================================================

func _sort_typing_speed_intervals() -> void:
	_typing_speed_intervals.sort_custom(
		func(a: Dictionary, b: Dictionary):
			if a["start"] != b["start"]:
				return a["start"] < b["start"]
			else:
				return a["end"] < b["end"]
	)


func _get_typing_speed_at(index: int) -> float:
	if _typing_speed_intervals.is_empty():
		return typing_speed

	var lo: int = 0
	var hi: int = _typing_speed_intervals.size() - 1
	var candidate_idx: int = -1

	while lo <= hi:
		var mid: int = (lo + hi) / 2
		var mid_interval: Dictionary = _typing_speed_intervals[mid]

		if mid_interval["start"] <= index:
			candidate_idx = mid
			lo = mid + 1
		else:
			hi = mid - 1

	if candidate_idx == -1:
		return typing_speed

	var i: int = candidate_idx

	while i >= 0 and _typing_speed_intervals[i]["start"] <= index:
		if index <= _typing_speed_intervals[i]["end"]:
			return _typing_speed_intervals[i]["value"]

		i -= 1

	return typing_speed

#endregion
