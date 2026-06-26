class_name SeedButtonList
extends HFlowContainer

signal seed_drag_started(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)
signal seed_drag_moved(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)
signal seed_drag_released(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)

const BUTTON_SCENE := preload("res://scene/ui/seed/seed_button.tscn")

var debug_numbers_visible := false
var sub_skill_drag_enabled := false


# 初期化
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("h_separation", 2)
	add_theme_constant_override("v_separation", 2)


# 種sources設定
func set_seed_sources(sources: Array) -> void:
	_clear_buttons()
	for source in sources:
		if source is Resource and _has_seed(source as Resource):
			_add_seed_button_list(source as Resource)


# デバッグ番号visible設定
func set_debug_numbers_visible(is_visible: bool) -> void:
	debug_numbers_visible = is_visible
	for child in get_children():
		if child is SeedButton:
			(child as SeedButton).set_debug_numbers_visible(debug_numbers_visible)


# subスキルドラッグenabled設定
func set_sub_skill_drag_enabled(is_enabled: bool) -> void:
	sub_skill_drag_enabled = is_enabled
	for child in get_children():
		if child is SeedButton:
			(child as SeedButton).set_sub_skill_drag_enabled(sub_skill_drag_enabled)


# 種ボタン追加
func _add_seed_button_list(source: Resource) -> void:
	# ボタン
	var button := BUTTON_SCENE.instantiate() as SeedButton
	add_child(button)
	button.set_seed_source(source)
	button.set_debug_numbers_visible(debug_numbers_visible)
	button.set_sub_skill_drag_enabled(sub_skill_drag_enabled)
	button.seed_drag_started.connect(_on_seed_drag_started)
	button.seed_drag_moved.connect(_on_seed_drag_moved)
	button.seed_drag_released.connect(_on_seed_drag_released)


# buttons消去
func _clear_buttons() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


# 種スキル判定
func _has_seed(source: Resource) -> bool:
	return source is SeedInfo


# 開始処理
func _on_seed_drag_started(
	button: SeedButton,
	seed: SeedInfo,
	mouse_position: Vector2
) -> void:
	seed_drag_started.emit(button, seed, mouse_position)


# 移動処理
func _on_seed_drag_moved(
	button: SeedButton,
	seed: SeedInfo,
	mouse_position: Vector2
) -> void:
	seed_drag_moved.emit(button, seed, mouse_position)


# 離上処理
func _on_seed_drag_released(
	button: SeedButton,
	seed: SeedInfo,
	mouse_position: Vector2
) -> void:
	seed_drag_released.emit(button, seed, mouse_position)
