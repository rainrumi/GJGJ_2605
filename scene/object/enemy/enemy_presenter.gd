class_name EnemyPresenter
extends RefCounted

var _attack_resolver: EnemyAttackResolver # 攻撃値計算
var _model: EnemyData # 敵モデル
var _view: EnemyView # 敵表示


# 依存関係設定
func setup(attack_resolver: EnemyAttackResolver) -> void:
	_attack_resolver = attack_resolver


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
	if result == null or result.enemy == null or result.enemy.enemy_view == null:
		return
	result.enemy.enemy_view.show_damage_values(result.damage_values)


# 攻撃表示更新
func refresh_attack_displays(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes := 0
) -> void:
	for enemy in enemies:
		if enemy == null or enemy.is_Acided():
			continue
		var display_damage := _attack_resolver.get_enemy_attack_damage(enemy, enemies, stomach, minutes) # 表示攻撃値
		enemy.set_display_damage(display_damage)
