extends Node

signal debug_enabled_changed(is_enabled: bool)

var debug_enabled := false


# デバッグenabled設定
func set_debug_enabled(is_enabled: bool) -> void:
	if debug_enabled == is_enabled:
		return
	debug_enabled = is_enabled
	debug_enabled_changed.emit(debug_enabled)


# デバッグenabled切替
func toggle_debug_enabled() -> void:
	set_debug_enabled(not debug_enabled)
