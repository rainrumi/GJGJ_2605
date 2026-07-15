class_name EnemyPresenter
extends RefCounted

var _model: EnemyData # 敵モデル
var _view: EnemyView # 敵表示


# Model表示接続
func bind(model: EnemyData, view: EnemyView) -> void:
	unbind()
	_model = model
	_view = view
	_model.hp.changed.connect(_on_hp_changed)
	_model.hp.damaged.connect(_on_damaged)
	_model.hp.healed.connect(_on_healed)
	_model.attack.changed.connect(_on_attack_changed)
	_model.stomach_status.digested.connect(_on_digested)
	_model.stomach_status.revived.connect(_on_revived)
	_on_hp_changed(_model.hp.current, _model.hp.maximum)
	_on_attack_changed(_model.attack.get_display_value())


# Model表示解除
func unbind() -> void:
	if _model == null:
		return
	_disconnect(_model.hp.changed, _on_hp_changed)
	_disconnect(_model.hp.damaged, _on_damaged)
	_disconnect(_model.hp.healed, _on_healed)
	_disconnect(_model.attack.changed, _on_attack_changed)
	_disconnect(_model.stomach_status.digested, _on_digested)
	_disconnect(_model.stomach_status.revived, _on_revived)
	_model = null
	_view = null


# Signal接続解除
func _disconnect(source_signal: Signal, callback: Callable) -> void:
	if source_signal.is_connected(callback):
		source_signal.disconnect(callback)


# HP表示反映
func _on_hp_changed(current: int, _maximum: int) -> void:
	if _view != null:
		_view.show_hp(current)


# 被弾表示反映
func _on_damaged(_amount: int) -> void:
	if _view != null:
		_view.pulse_damage()


# 回復表示反映
func _on_healed(_amount: int) -> void:
	if _view != null:
		_view.pulse_hp()


# 攻撃表示反映
func _on_attack_changed(display_value: int) -> void:
	if _view != null:
		_view.show_damage(display_value)


# 消化表示反映
func _on_digested() -> void:
	if _view != null:
		_view.play_digested()


# 復活表示反映
func _on_revived() -> void:
	if _view != null:
		_view.show_revived()


# 消化結果表示
func present_digestion_result(result: EnemyDigestionResult) -> void:
	if result == null or result.enemy == null or result.enemy.data != _model or _view == null:
		return
	_view.show_damage_values(result.damage_values)


# 攻撃表示反映
func present_attack(value: int) -> void:
	if _view != null:
		_view.show_damage(value)


# 攻撃表示値設定
func set_attack_display(value: int) -> void:
	if _model != null:
		_model.attack.set_display_override(maxi(0, value))


# HP表示反映
func present_hp(value: int) -> void:
	if _view != null:
		_view.show_hp(value)


# 消化表示反映
func present_digested() -> void:
	if _view != null:
		_view.play_digested()


# 画像設定
func setup_texture(texture: Texture2D, target_size: Vector2) -> void:
	if _view != null:
		_view.setup_texture(texture, target_size)


# 表示サイズ更新
func update_display_size(target_size: Vector2) -> void:
	if _view != null:
		_view.update_display_size(target_size)


# 表示状態設定
func set_presented(value: bool) -> void:
	if _view != null:
		_view.set_presented(value)


# ホバー設定
func set_hovered(value: bool) -> void:
	if _view != null:
		_view.set_hovered(value)


# ツール表示
func show_tooltip(debug_text: String, debug_visible: bool) -> void:
	if _view != null:
		_view.show_tooltip(debug_text, debug_visible)


# ツール非表示
func hide_tooltip() -> void:
	if _view != null:
		_view.hide_tooltip()


# プレビュー画像取得
func get_preview_texture() -> Texture2D:
	return _view.get_preview_texture() if _view != null else null


# プレビュー倍率取得
func get_preview_scale() -> Vector2:
	return _view.get_preview_scale() if _view != null else Vector2.ONE


# HP強調
func present_hp_pulse() -> void:
	if _view != null:
		_view.pulse_hp()


# 被弾強調
func present_damage_pulse() -> void:
	if _view != null:
		_view.pulse_damage()


# 被弾値表示
func present_damage_popup(amount: int) -> void:
	if _view != null:
		_view.show_damage_popup(amount)


# 被弾一覧表示
func present_damage_values(values: Array) -> void:
	if _view != null:
		_view.show_damage_values(values)


# 表示矩形取得
func get_global_rect() -> Rect2:
	return _view.get_global_rect() if _view != null else Rect2()


# 見た目初期化
func reset_visuals() -> void:
	if _view != null:
		_view.reset_visuals()


# 状態色更新
func update_status_colors(has_main_effect: bool) -> void:
	if _view != null:
		_view.update_status_colors(has_main_effect)
