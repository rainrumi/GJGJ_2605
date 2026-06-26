extends ScrollContainer

const SCROLL_BAR_SCRIPT := preload("res://scene/main/stage_select/stage_choices_scroll_bar.gd")


# 初期化
func _ready() -> void:
	# scrollbar
	var scroll_bar := get_v_scroll_bar()
	scroll_bar.set_script(SCROLL_BAR_SCRIPT)
	scroll_bar.call("match_main_background_color")
