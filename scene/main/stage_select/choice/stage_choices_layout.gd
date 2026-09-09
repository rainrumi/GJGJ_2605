extends VBoxContainer

@onready var _title_padding: MarginContainer = $StageChoicesPadding
@onready var _stage_choices_scroll: ScrollContainer = $StageChoicesListScroll
@onready var _stage_choices_padding: MarginContainer = $StageChoicesListScroll/StageChoicesPadding
@onready var _stage_choices: StageSelectChoiceList = $StageChoicesListScroll/StageChoicesPadding/StageChoices
@onready var _viewport: Control = get_parent().get_parent()


func _ready() -> void:
	_viewport.resized.connect(_queue_scroll_height_update)
	_stage_choices.minimum_size_changed.connect(_queue_scroll_height_update)
	_queue_scroll_height_update()


func _queue_scroll_height_update() -> void:
	call_deferred("_update_scroll_height")


func _update_scroll_height() -> void:
	var available_height := _viewport.size.y
	var title_height := _title_padding.get_combined_minimum_size().y
	var separation := get_theme_constant("separation")
	var maximum_scroll_height := maxf(available_height - title_height - separation, 0.0)
	var content_height := _stage_choices_padding.get_combined_minimum_size().y
	var target_height := minf(content_height, maximum_scroll_height)
	if is_equal_approx(_stage_choices_scroll.custom_minimum_size.y, target_height):
		return
	_stage_choices_scroll.custom_minimum_size.y = target_height
