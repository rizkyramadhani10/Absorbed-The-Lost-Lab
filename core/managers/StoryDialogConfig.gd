# StoryDialogConfig.gd
class_name StoryDialogConfig
extends Resource

@export var target_stage: GameState.StoryStage
@export_file("*.tres") var dialog_path: String = ""
@export var start_id: int = 1

var has_played: bool = false
