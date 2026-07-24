class_name HpView
extends NinePatchRect

const HP_DAMAGE_FLOAT_DISTANCE := 8.0
const HP_DAMAGE_TWEEN_DURATION := 0.35
const HP_DAMAGE_HIDE_DELAY := 0.15
const HP_GAUGE_TWEEN_DURATION := 0.2

signal tooltip_requested(view: HpView)
signal tooltip_hide_requested(view: HpView)

@onready var hp_gauge: HpGaugeView = $HpGauge
@onready var hp_heal_plan: HpHealPlanView = $HpHealPlan
@onready var hp_text: HpTextView = $HpText
@onready var tooltip_hit_area: Control = $TooltipHitArea
@onready var hp_tooltip: HpTooltip = $HpView_tooltip

var _current_hp := 0
var _max_hp := 1
var _planned_recovery_rate := 0.0
var _hp_damage_preview_label: Label
var _is_hp_recovering := false
var _has_hp_value := false
var _active_hp_value_popup_slots: Array[Control] = []


# 初期化
func _ready() -> void:
	_prepare_mouse_filter()
	_prepare_draw_order()
	_connect_child_signals()
	hp_gauge.capture_full_width()
	_create_hp_damage_preview()
	_update_hp_heal_plan()
	tooltip_hit_area.mouse_entered.connect(_on_mouse_entered)
	tooltip_hit_area.mouse_exited.connect(_on_mouse_exited)


# HP設定
func set_hp(
	current_hp: int,
	max_hp: int,
	animated: bool = true,
	explicit_recovered_hp: int = -1
) -> void:
	# HP
	var previous_hp := _current_hp
	_max_hp = maxi(1, max_hp)
	_current_hp = clampi(current_hp, 0, _max_hp)
	hp_text.set_hp_values(_current_hp, _max_hp)
	# HP比率
	var hp_ratio := clampf(float(_current_hp) / float(_max_hp), 0.0, 1.0)
	# 対象幅
	var target_width := hp_gauge.get_full_width() * hp_ratio
	# 回復判定
	var is_recovering := _has_hp_value and animated and _current_hp > previous_hp
	# 回復HP
	var recovered_hp := (
		_current_hp - previous_hp
		if explicit_recovered_hp < 0
		else explicit_recovered_hp
	)
	_has_hp_value = true
	hp_gauge.kill_width_tween()
	_is_hp_recovering = is_recovering
	if _current_hp > 0:
		hp_gauge.show_gauge()
	if not animated:
		hp_gauge.set_width_immediate(target_width, _current_hp == 0)
		_is_hp_recovering = false
		_update_hp_heal_plan()
		return
	if is_recovering:
		_show_hp_heal_plan(target_width)
	else:
		_update_hp_heal_plan()
	_show_heal_value(recovered_hp)
	hp_gauge.animate_width(target_width, HP_GAUGE_TWEEN_DURATION, _current_hp == 0)


# 戦闘HP設定
func set_battle_hp_info(
	current_hp: int,
	max_hp: int,
	rest_minutes: int,
	rest_hp_rate: float,
	rest_recovery_bonus_rate: float,
	explicit_recovered_hp: int = -1
) -> void:
	set_hp(current_hp, max_hp, true, explicit_recovered_hp)
	set_tooltip_info(rest_minutes, rest_hp_rate, rest_recovery_bonus_rate)


# HPツール情報設定
func set_tooltip_info(
	rest_minutes: int,
	rest_hp_rate: float,
	rest_recovery_bonus_rate: float
) -> void:
	hp_tooltip.set_hp_info(
		_current_hp,
		_max_hp,
		rest_minutes,
		rest_hp_rate,
		rest_recovery_bonus_rate
	)


# 予定回復率設定
func set_planned_recovery_rate(recovery_rate: float) -> void:
	_planned_recovery_rate = maxf(0.0, recovery_rate)
	_update_hp_heal_plan()


# ダメージ予告表示
func show_damage_preview(amount: int) -> void:
	_hp_damage_preview_label.text = "-%d" % amount
	_hp_damage_preview_label.position = Vector2(size.x - 21.0, -8.0)
	_hp_damage_preview_label.visible = true


# ダメージ予告非表示
func hide_damage_preview() -> void:
	_hp_damage_preview_label.visible = false


# ダメージ値表示
func show_damage_values(damage_values: Array[int]) -> void:
	# ダメージ文言
	var damage_texts: Array[String] = []
	for damage in damage_values:
		if damage > 0:
			damage_texts.append("-%d" % damage)
	if damage_texts.is_empty():
		return
	# ラベル
	var label := hp_text.create_damage_value_label(damage_texts)
	_show_hp_value_popup(label)


# ツール表示
func show_tooltip() -> void:
	show_tooltip_at(global_position)


# ツールat表示
func show_tooltip_at(anchor_global_position: Vector2) -> void:
	hp_tooltip.show_tooltip_at(anchor_global_position)


# ツール非表示
func hide_tooltip() -> void:
	hp_tooltip.hide_tooltip()


# 回復値表示
func _show_heal_value(amount: int) -> void:
	if amount <= 0:
		return
	# ラベル
	var label := hp_text.create_heal_value_label(amount)
	_show_hp_value_popup(label)


# マウス入力準備
func _prepare_mouse_filter() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_hit_area.mouse_filter = Control.MOUSE_FILTER_STOP


# 描画順準備
func _prepare_draw_order() -> void:
	move_child(hp_heal_plan, hp_gauge.get_index())
	hp_heal_plan.set_draw_order(0)
	hp_gauge.set_draw_order(0)
	hp_text.set_draw_order(1)


# 子信号接続
func _connect_child_signals() -> void:
	if not hp_gauge.width_tween_finished.is_connected(_on_hp_gauge_width_tween_finished):
		hp_gauge.width_tween_finished.connect(_on_hp_gauge_width_tween_finished)


# HPダメージ予告作成
func _create_hp_damage_preview() -> void:
	_hp_damage_preview_label = Label.new()
	_hp_damage_preview_label.name = "RemoveEnemyDamagePreview"
	_hp_damage_preview_label.visible = false
	_hp_damage_preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_text.apply_damage_label_style(_hp_damage_preview_label, 14, Color.BLACK)
	add_child(_hp_damage_preview_label)


# HP増減値表示
func _show_hp_value_popup(label: Label) -> void:
	for slot in _active_hp_value_popup_slots:
		slot.position.y -= label.size.y
	var slot := Control.new()
	slot.name = "HpValuePopup"
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.position = label.position
	slot.size = label.size
	label.position = Vector2.ZERO
	add_child(slot)
	slot.add_child(label)
	_active_hp_value_popup_slots.append(slot)
	_play_hp_value_popup_tween(label, slot)


# HP増減値演出再生
func _play_hp_value_popup_tween(label: Label, slot: Control) -> void:
	# 演出
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - HP_DAMAGE_FLOAT_DISTANCE, HP_DAMAGE_TWEEN_DURATION)
	tween.tween_property(label, "modulate:a", 1.0, HP_DAMAGE_TWEEN_DURATION)
	tween.chain().tween_interval(HP_DAMAGE_HIDE_DELAY)
	tween.chain().tween_property(label, "modulate:a", 0.0, HP_DAMAGE_TWEEN_DURATION)
	tween.chain().tween_callback(_on_hp_value_popup_finished.bind(slot))


# HP増減値演出完了
func _on_hp_value_popup_finished(slot: Control) -> void:
	_active_hp_value_popup_slots.erase(slot)
	slot.queue_free()


# HP回復予定更新
func _update_hp_heal_plan() -> void:
	if _is_hp_recovering:
		return
	# 比率
	var current_ratio := clampf(float(_current_hp) / float(_max_hp), 0.0, 1.0)
	# 対象HP
	var target_hp := mini(_max_hp, _current_hp + ceili(float(_max_hp) * _planned_recovery_rate))
	# 予定回復
	var planned_recovery := target_hp - _current_hp
	# 対象比率
	var target_ratio := clampf(float(target_hp) / float(_max_hp), 0.0, 1.0)
	# 対象幅
	var target_width := hp_gauge.get_full_width() * target_ratio
	if target_ratio <= current_ratio:
		hp_heal_plan.hide_plan()
		hp_text.set_hp_values(_current_hp, _max_hp)
		return
	hp_text.set_hp_values(_current_hp, _max_hp, planned_recovery)
	_show_hp_heal_plan(target_width)


# HP回復予定表示
func _show_hp_heal_plan(target_width: float) -> void:
	hp_heal_plan.show_plan(target_width, hp_gauge.position, hp_gauge.size.y)
	hp_gauge.set_draw_order(0)
	hp_text.set_draw_order(1)


# 完了処理
func _on_hp_gauge_width_tween_finished() -> void:
	_is_hp_recovering = false
	_update_hp_heal_plan()


# hover開始
func _on_mouse_entered() -> void:
	tooltip_requested.emit(self)


# hover終了
func _on_mouse_exited() -> void:
	tooltip_hide_requested.emit(self)
