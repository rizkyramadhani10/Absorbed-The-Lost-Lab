class_name LabTriggerConfig extends Resource

@export var trigger_node: NodePath
@export var target_stage: GameState.StoryStage = GameState.StoryStage.CHECKED_MONITOR
@export var advance_story_to: GameState.StoryStage = GameState.StoryStage.CHECKED_TIME_MACHINE
@export_file("*.tres") var dialog_path: String = ""
@export var completion_flag: String = ""
