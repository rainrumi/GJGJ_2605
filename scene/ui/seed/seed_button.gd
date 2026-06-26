class_name SeedButton
extends Button

signal seed_drag_started(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)
signal seed_drag_moved(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)
signal seed_drag_released(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)

const TOOLTIP_OFFSET := Vector2(18.0, -8.0)
const TOOLTIP_SCENE := preload("res://scene/ui/seed/seed_tooltip.tscn")
const LOW_SUB_SKILL_USES_COLOR := Color(1.0, 0.02745098, 0.21176471, 1.0)
const NORMAL_ICON_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const SUB_SKILL_USE_COUNT := 1

@onready var frame: TextureRect = $Frame
@onready var icon_rect: TextureRect = $Icon

var source_data: Resource
var icon_source_data: Resource
var seed: SeedInfo
var tooltip_panel: SeedTooltip
var debug_numbers_visible := false
var sub_skill_drag_enabled := false
# 現状はUI表示を兼ねた一時的な使用回数。永続状態が必要になったらRuntimeStateへ移す。
var _display_remaining_sub_skill_uses := 0
var _dragging := false


# 初期化
func _ready() -> void:
	custom_minimum_size = Vector2(16.0, 16.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	flat = true
	icon_rect.visible = icon_rect.texture != null
	_create_tooltip_panel()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# 種元データ設定
func set_seed_source(source: Resource) -> void:
	source_data = source
	seed = null
	if source is SeedInfo:
		seed = source as SeedInfo
	set_seed_icon_source(source)
	_display_remaining_sub_skill_uses = SUB_SKILL_USE_COUNT if _has_sub_skill() else 0
	disabled = seed == null
	_update_drag_state()
	_refresh_tooltip()


# 種アイコン元データ設定
func set_seed_icon_source(source: Resource) -> void:
	icon_source_data = source
	if source is SeedInfo:
		set_seed_icon_texture((source as SeedInfo).texture)
	elif source is SeedInfo:
		set_seed_icon_texture((source as SeedInfo).texture)
	else:
		set_seed_icon_texture(null)


# 種アイコン画像設定
func set_seed_icon_texture(texture: Texture2D) -> void:
	icon_rect.texture = texture
	icon_rect.visible = texture != null


# 種元データ取得
func get_seed_source() -> Resource:
	return source_data


# remainingsubスキルuse取得
func get_remaining_sub_skill_uses() -> int:
	return _display_remaining_sub_skill_uses


# デバッグ番号visible設定
func set_debug_numbers_visible(is_visible: bool) -> void:
	debug_numbers_visible = is_visible
	_refresh_tooltip()


# subスキルドラッグenabled設定
func set_sub_skill_drag_enabled(is_enabled: bool) -> void:
	sub_skill_drag_enabled = is_enabled
	_update_drag_state()


# subスキルuse消費
func consume_sub_skill_use() -> void:
	_display_remaining_sub_skill_uses = maxi(0, _display_remaining_sub_skill_uses - 1)
	_update_drag_state()
	_refresh_tooltip()


# 毎フレーム処理
func _process(_delta: float) -> void:
	if not _dragging or seed == null:
		return
	seed_drag_moved.emit(self, seed, get_viewport().get_mouse_position())


# 入力処理
func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseButton:
		# マウスボタン
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
			_dragging = false
			seed_drag_released.emit(self, seed, mouse_button.position)


# GUI入力処理
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# マウスボタン
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			_try_use_sub_skill(mouse_button.position)


# ツール更新
func _refresh_tooltip() -> void:
	if seed == null:
		tooltip_text = ""
		if tooltip_panel != null:
			tooltip_panel.set_text("")
		return
	# 文言
	var text := _get_tooltip_text()
	tooltip_text = ""
	if tooltip_panel != null:
		tooltip_panel.set_text(text)


# ツール文言取得
func _get_tooltip_text() -> String:
	# 行一覧
	var lines: Array[String] = [
		_get_title_text(),
		"メインスキル: %s" % SeedDescription.get_main_description(seed),
	]
	if _has_sub_skill():
		lines.append("サブスキル: %s" % SeedDescription.get_sub_description(seed))
	if debug_numbers_visible:
		lines.append("ID: %d" % seed.skill_id)
	return "\n".join(lines)


# ツールpanel作成
func _create_tooltip_panel() -> void:
	tooltip_panel = TOOLTIP_SCENE.instantiate() as SeedTooltip
	add_child(tooltip_panel)
	_refresh_tooltip()


# ホバー開始
func _on_mouse_entered() -> void:
	if seed == null or tooltip_panel == null:
		return
	tooltip_panel.global_position = TooltipPositioner.get_tooltip_position(
		global_position,
		tooltip_panel.size,
		get_viewport().get_visible_rect(),
		TOOLTIP_OFFSET
	)
	tooltip_panel.visible = true


# ホバー終了
func _on_mouse_exited() -> void:
	if tooltip_panel != null:
		tooltip_panel.visible = false


# title文言取得
func _get_title_text() -> String:
	if _is_rare_seed():
		return "%s(レア)" % seed.display_name
	return seed.display_name


# rare種判定
func _is_rare_seed() -> bool:
	return seed != null and seed.rarity == SeedInfo.Rarity.RARE


# usesubスキル試行
func _try_use_sub_skill(mouse_position: Vector2) -> void:
	if not _can_use_sub_skill():
		return
	_dragging = true
	seed_drag_started.emit(self, seed, mouse_position)


# usesubスキル判定
func _can_use_sub_skill() -> bool:
	return sub_skill_drag_enabled and seed != null and seed.sub_skill_mode != SeedInfo.SubSkillMode.None and _has_sub_skill() and _display_remaining_sub_skill_uses > 0


# subスキル判定
func _has_sub_skill() -> bool:
	return SeedDescription.has_sub_skill(seed)


# ドラッグstate更新
func _update_drag_state() -> void:
	if icon_rect != null:
		icon_rect.self_modulate = LOW_SUB_SKILL_USES_COLOR if _can_use_sub_skill() and _display_remaining_sub_skill_uses <= 1 else NORMAL_ICON_COLOR
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _can_use_sub_skill() else Control.CURSOR_ARROW
