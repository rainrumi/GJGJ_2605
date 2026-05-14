class_name BattleUI
extends CanvasLayer

signal digestion_requested
signal debug_message_requested(is_active: bool)
signal debug_reroll_requested

@onready var digest_summary: DigestSummaryView = $PassiveGuideFrame
@onready var hp_status: HpView = $HpFrame
@onready var time_status: TimeStatusView = $TimeBar
@onready var digestion_button: DigestionButtonView = $DigestionFrame
@onready var status_panel: StatusPanelView = $StatusPanel
@onready var nightmare_tooltip: NightmareTooltipView = $NightmareTooltipPanel
@onready var digest_tooltip: DigestDamageTooltipView = $DigestDamageTooltipPanel


# 初期化
func _ready() -> void:
	_connect_child_signals()
	hide_nightmare_tooltip()
	hide_digest_damage_tooltip()


# キー入力処理
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_D:
			status_panel.toggle_debug_message()
		if key_event.keycode == KEY_R:
			status_panel.request_debug_reroll()


# 戦闘表示初期化
func reset_for_battle(max_hp: int, minutes: int, message: String) -> void:
	set_hp(max_hp, max_hp)
	set_time(minutes)
	digest_summary.reset_summary()
	digest_tooltip.set_damage_info(0, 0, 0, 0.0, 0, 0.0)
	set_message(message)
	set_debug_message("")
	set_debug_button_active(false)
	set_digestion_count(0)
	set_digestion_button_visible(true)
	hide_hp_damage_preview()
	hide_time_elapsed()
	hide_nightmare_tooltip()
	hide_digest_damage_tooltip()


# HPを反映
func set_hp(current_hp: int, max_hp: int) -> void:
	hp_status.set_hp(current_hp, max_hp)


# 時刻を反映
func set_time(minutes: int) -> void:
	time_status.set_time(minutes)


# メッセージ反映
func set_message(message: String) -> void:
	status_panel.set_message(message)


# デバッグ文言
func set_debug_message(message: String) -> void:
	status_panel.set_debug_message(message)


# 悪夢詳細表示
func show_nightmare_tooltip(enemy: Enemy, debug_number_text: String, debug_numbers_visible: bool) -> void:
	hide_digest_damage_tooltip()
	nightmare_tooltip.show_enemy(enemy, debug_number_text, debug_numbers_visible)


# 悪夢詳細非表示
func hide_nightmare_tooltip() -> void:
	nightmare_tooltip.hide_tooltip()


# 消化詳細表示
func show_digest_damage_tooltip() -> void:
	hide_nightmare_tooltip()
	digest_tooltip.show_tooltip()


# 消化詳細非表示
func hide_digest_damage_tooltip() -> void:
	digest_tooltip.hide_tooltip()


# 消化情報反映
func set_digest_damage_info(
	total_damage: int,
	base_damage: int,
	seed_buff: int,
	seed_rate: float,
	nightmare_buff: int,
	nightmare_rate: float
) -> void:
	digest_summary.set_digest_damage(total_damage)
	digest_tooltip.set_damage_info(total_damage, base_damage, seed_buff, seed_rate, nightmare_buff, nightmare_rate)


# 消化効率反映
func set_digest_efficiency_minutes(amount_minutes: float) -> void:
	digest_summary.set_digest_efficiency_minutes(amount_minutes)


# デバッグ状態
func set_debug_button_active(is_active: bool) -> void:
	status_panel.set_debug_button_active(is_active)


# 消化数反映
func set_digestion_count(count: int) -> void:
	digestion_button.set_count(count)


# 消化ボタン表示
func set_digestion_button_visible(is_visible: bool) -> void:
	digestion_button.set_button_visible(is_visible)


# 消化ボタン判定
func is_digestion_button_hit(mouse_position: Vector2) -> bool:
	return digestion_button.is_hit(mouse_position)


# 経過時間表示
func show_time_elapsed(amount_minutes: int) -> void:
	time_status.show_elapsed(amount_minutes)


# 経過時間非表示
func hide_time_elapsed() -> void:
	time_status.hide_elapsed()


# HP予告表示
func show_hp_damage_preview(amount: int) -> void:
	hp_status.show_damage_preview(amount)


# HP予告非表示
func hide_hp_damage_preview() -> void:
	hp_status.hide_damage_preview()


# HPダメージ表示
func show_hp_damage_values(damage_values: Array[int]) -> void:
	hp_status.show_damage_values(damage_values)


# 子signal接続
func _connect_child_signals() -> void:
	digestion_button.digestion_requested.connect(_on_digestion_requested)
	status_panel.debug_message_requested.connect(_on_debug_message_requested)
	status_panel.debug_reroll_requested.connect(_on_debug_reroll_requested)
	digest_summary.detail_requested.connect(show_digest_damage_tooltip)
	digest_summary.detail_closed.connect(hide_digest_damage_tooltip)


# 消化要求中継
func _on_digestion_requested() -> void:
	digestion_requested.emit()


# Debug要求中継
func _on_debug_message_requested(is_active: bool) -> void:
	debug_message_requested.emit(is_active)


# Reroll要求中継
func _on_debug_reroll_requested() -> void:
	debug_reroll_requested.emit()
