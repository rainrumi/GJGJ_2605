class_name BattleUI
extends CanvasLayer

signal Acidion_requested
signal debug_message_requested(is_active: bool)
signal debug_reroll_requested
signal debug_stomach_size_requested(delta_columns: int, delta_rows: int)
signal debug_seed_requested
signal nightmare_previous_page_requested
signal nightmare_next_page_requested
signal seed_drag_started(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)
signal seed_drag_moved(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)
signal seed_drag_released(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)

@onready var acid_damage_view: AcidDamageView = $AcidDamageView
@onready var acid_interval_view: AcidIntervalView = $AcidIntervalView
@onready var hp_view: HpView = $HpView
@onready var seed_button_list: SeedButtonList = $SeedButtonList
@onready var time_view: TimeView = $TimeView
@onready var acid_button: AcidButton = $AcidButton
@onready var debug_panel: DebugPanel = $DebugPanel
@onready var nightmare_previous_page_button: Button = $NightmarePreviousPageButton
@onready var nightmare_next_page_button: Button = $NightmareNextPageButton

var _rest_minutes := 30
var _rest_hp_rate := 0.1
var _rest_recovery_bonus_rate := 0.0
var _current_tooltip_owner: Object = null
var _current_tooltip_hide: Callable = Callable()

# -----------------------------------------------------------

# 初期化
func _ready() -> void:
	seed_button_list.set_sub_skill_drag_enabled(true)
	_connect_child_signals()
	_hide_all_tooltips()

# -----------------------------------------------------------

# 未処理入力
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		# keyイベント
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_D:
			debug_panel.toggle_debug_message()
		if key_event.keycode == KEY_R:
			debug_panel.request_debug_reroll()

# -----------------------------------------------------------

# for戦闘初期化
func reset_for_battle(
	max_hp: int,
	minutes: int,
	message: String,
	rest_minutes: int = 30,
	rest_hp_rate: float = 0.1,
	rest_recovery_bonus_rate: float = 0.0,
	acid_interval_minutes: float = 30.0
) -> void:
	_rest_minutes = rest_minutes
	_rest_hp_rate = rest_hp_rate
	_rest_recovery_bonus_rate = rest_recovery_bonus_rate
	set_hp(max_hp, max_hp)
	set_time(minutes)
	set_acid_damage_info(0, 0, 0, 0.0, 0, 0.0)
	set_acid_interval_minutes(acid_interval_minutes)
	time_view.set_tooltip_info()
	set_message(message)
	set_debug_message("")
	set_seed_sources([])
	set_seed_debug_numbers_visible(DebugState.debug_enabled)
	set_debug_button_active(DebugState.debug_enabled)
	set_acidion_count(0)
	set_acid_button_visible(true)
	hide_hp_damage_preview()
	hide_time_elapsed()
	_hide_all_tooltips()

# -----------------------------------------------------------

# HP設定
func set_hp(current_hp: int, max_hp: int) -> void:
	hp_view.set_battle_hp_info(current_hp, max_hp, _rest_minutes, _rest_hp_rate, _rest_recovery_bonus_rate)


# 休憩回復補正率設定
func set_rest_recovery_bonus_rate(rest_recovery_bonus_rate: float) -> void:
	_rest_recovery_bonus_rate = rest_recovery_bonus_rate


# 時間設定
func set_time(minutes: int) -> void:
	time_view.set_time(minutes)


# 文言設定
func set_message(message: String) -> void:
	debug_panel.set_message(message)


# デバッグ文言設定
func set_debug_message(message: String) -> void:
	debug_panel.set_debug_message(message)


# 夢種スキルsources設定
func set_seed_sources(sources: Array) -> void:
	seed_button_list.set_seed_sources(sources)


# 夢種デバッグ番号visible設定
func set_seed_debug_numbers_visible(is_visible: bool) -> void:
	seed_button_list.set_debug_numbers_visible(is_visible)

# -----------------------------------------------------------

# 悪夢ツール表示
func show_enemy_tooltip(enemy: Enemy, debug_number_text: String, debug_numbers_visible: bool) -> void:
	var show_func := func() -> void:
		if is_instance_valid(enemy):
			enemy.show_tooltip(debug_number_text, debug_numbers_visible)
	var hide_func := func() -> void:
		if is_instance_valid(enemy):
			enemy.hide_tooltip()
	_show_exclusive_tooltip(enemy, show_func, hide_func)


# 悪夢ツール非表示
func hide_enemy_tooltip(enemy: Enemy = null) -> void:
	_hide_current_tooltip(enemy)

# -----------------------------------------------------------

# 全ツール非表示
func _hide_all_tooltips() -> void:
	_hide_current_tooltip()

# -----------------------------------------------------------

# 消化ダメージ情報設定
func set_acid_damage_info(
	total_damage: int,
	base_damage: int,
	seed_buff: int,
	seed_rate: float,
	nightmare_buff: int,
	nightmare_rate: float
) -> void:
	acid_damage_view.set_damage_info(total_damage, base_damage, seed_buff, seed_rate, nightmare_buff, nightmare_rate)


# 消化interval分数設定
func set_acid_interval_minutes(
	amount_minutes: float,
	base_minutes: float = 30.0,
	seed_buff: int = 0,
	seed_rate: float = 0.0,
	nightmare_buff: int = 0,
	nightmare_rate: float = 0.0
) -> void:
	acid_interval_view.set_interval_info(amount_minutes, base_minutes, seed_buff, seed_rate, nightmare_buff, nightmare_rate)

# -----------------------------------------------------------

# デバッグボタンactive設定
func set_debug_button_active(is_active: bool) -> void:
	debug_panel.set_debug_button_active(is_active)


# 消化数設定
func set_acidion_count(count: int) -> void:
	acid_button.set_count(count)

# -----------------------------------------------------------

# 消化ボタンvisible設定
func set_acid_button_visible(is_visible: bool) -> void:
	acid_button.set_button_visible(is_visible)


# 悪夢ページ移動ボタン表示設定
func set_nightmare_page_navigation(has_previous: bool, has_next: bool) -> void:
	nightmare_previous_page_button.visible = has_previous
	nightmare_next_page_button.visible = has_next


# 消化ボタンhit判定
func is_acid_button_hit(mouse_position: Vector2) -> bool:
	return acid_button.is_hit(mouse_position)

# -----------------------------------------------------------

# 時間elapsed表示
func show_time_elapsed(amount_minutes: int) -> void:
	time_view.show_elapsed(amount_minutes)


# 時間elapsed非表示
func hide_time_elapsed() -> void:
	time_view.hide_elapsed()

# -----------------------------------------------------------

# HPダメージpreview表示
func show_hp_damage_preview(amount: int) -> void:
	hp_view.show_damage_preview(amount)


# HPダメージpreview非表示
func hide_hp_damage_preview() -> void:
	hp_view.hide_damage_preview()

# -----------------------------------------------------------

# HPダメージvalues表示
func show_hp_damage_values(damage_values: Array[int]) -> void:
	hp_view.show_damage_values(damage_values)

# -----------------------------------------------------------

# childsignals接続
func _connect_child_signals() -> void:
	
	acid_button.Acidion_requested.connect(_on_Acidion_requested)
	nightmare_previous_page_button.pressed.connect(_on_nightmare_previous_page_requested)
	nightmare_next_page_button.pressed.connect(_on_nightmare_next_page_requested)
	
	debug_panel.debug_message_requested.connect(_on_debug_message_requested)
	debug_panel.debug_reroll_requested.connect(_on_debug_reroll_requested)
	debug_panel.debug_stomach_size_requested.connect(_on_debug_stomach_size_requested)
	debug_panel.debug_seed_requested.connect(_on_debug_seed_requested)
	
	seed_button_list.seed_drag_started.connect(_on_seed_drag_started)
	seed_button_list.seed_drag_moved.connect(_on_seed_drag_moved)
	seed_button_list.seed_drag_released.connect(_on_seed_drag_released)
	
	acid_damage_view.tooltip_requested.connect(_on_view_tooltip_requested)
	acid_damage_view.tooltip_hide_requested.connect(_on_tooltip_hide_requested)
	
	acid_interval_view.tooltip_requested.connect(_on_view_tooltip_requested)
	acid_interval_view.tooltip_hide_requested.connect(_on_tooltip_hide_requested)
	
	time_view.tooltip_requested.connect(_on_view_tooltip_requested)
	time_view.tooltip_hide_requested.connect(_on_tooltip_hide_requested)
	
	hp_view.tooltip_requested.connect(_on_view_tooltip_requested)
	hp_view.tooltip_hide_requested.connect(_on_tooltip_hide_requested)

# -----------------------------------------------------------

# 排他ツール表示
func _show_exclusive_tooltip(
	owner: Object,
	show_callable: Callable,
	hide_callable: Callable
) -> void:
	if owner == null:
		return
	if _current_tooltip_owner != owner:
		_hide_current_tooltip()
	_current_tooltip_owner = owner
	_current_tooltip_hide = hide_callable
	if show_callable.is_valid():
		show_callable.call()

# -----------------------------------------------------------

# ツール非表示
func _hide_current_tooltip(owner: Object = null) -> void:
	if owner != null and owner != _current_tooltip_owner:
		return
	if _current_tooltip_hide.is_valid():
		_current_tooltip_hide.call()
	_current_tooltip_owner = null
	_current_tooltip_hide = Callable()


# ツール表示
func _show_view_tooltip(view: Object) -> void:
	var show_func := func() -> void:
		if is_instance_valid(view):
			var show_callable := Callable(view, "show_tooltip")
			if show_callable.is_valid():
				show_callable.call()
	var hide_func := func() -> void:
		if is_instance_valid(view):
			var hide_callable := Callable(view, "hide_tooltip")
			if hide_callable.is_valid():
				hide_callable.call()
	_show_exclusive_tooltip(view, show_func, hide_func)

# -----------------------------------------------------------

# ツール表示要求
func _on_view_tooltip_requested(view: Object) -> void:
	_show_view_tooltip(view)


# ツール非表示要求
func _on_tooltip_hide_requested(view: Object) -> void:
	_hide_current_tooltip(view)

# -----------------------------------------------------------

# 消化開始要求
func _on_Acidion_requested() -> void:
	Acidion_requested.emit()


# 前の悪夢ページ要求
func _on_nightmare_previous_page_requested() -> void:
	nightmare_previous_page_requested.emit()


# 次の悪夢ページ要求
func _on_nightmare_next_page_requested() -> void:
	nightmare_next_page_requested.emit()

# -----------------------------------------------------------

# デバッグ開始要求
func _on_debug_message_requested(is_active: bool) -> void:
	debug_message_requested.emit(is_active)


# デバッグリロール要求
func _on_debug_reroll_requested() -> void:
	debug_reroll_requested.emit()


# デバッグ胃袋サイズ変更要求
func _on_debug_stomach_size_requested(delta_columns: int, delta_rows: int) -> void:
	debug_stomach_size_requested.emit(delta_columns, delta_rows)


# デバッグ種生成要求
func _on_debug_seed_requested() -> void:
	debug_seed_requested.emit()

# -----------------------------------------------------------

# 種移動開始
func _on_seed_drag_started(
	button: SeedButton,
	seed: SeedInfo,
	mouse_position: Vector2
) -> void:
	seed_drag_started.emit(button, seed, mouse_position)

# -----------------------------------------------------------

# 種移動処理
func _on_seed_drag_moved(
	button: SeedButton,
	seed: SeedInfo,
	mouse_position: Vector2
) -> void:
	seed_drag_moved.emit(button, seed, mouse_position)


# 種移動キャンセル処理
func _on_seed_drag_released(
	button: SeedButton,
	seed: SeedInfo,
	mouse_position: Vector2
) -> void:
	seed_drag_released.emit(button, seed, mouse_position)
