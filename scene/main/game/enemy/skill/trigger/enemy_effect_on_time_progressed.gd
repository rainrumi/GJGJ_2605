class_name EnemyEffectOnTimeProgressed
extends EnemyEffectWithTimeData

var _battle_clock: BattleClock # 時刻Signal元
var _refresh_processor: EnemyEffectRefreshProcessor # 更新Signal元
var _default_attack_refresh: EnemyEffectRefreshDefaultAttack # 通常攻撃更新


# 時刻Trigger設定
func setup_time_trigger(clock: BattleClock, refresh_processor: EnemyEffectRefreshProcessor) -> void:
	_battle_clock = clock
	_refresh_processor = refresh_processor


# 発動Signal接続
func bind() -> void:
	if _battle_clock != null:
		connect_trigger(_battle_clock.progressed, _on_time_progressed)
	_bind_default_attack_refresh()


# 時刻進行受信
func _on_time_progressed(elapsed_seconds: int, current_seconds: int) -> void:
	queue_activation(ProgressTimeActivationData.new(elapsed_seconds, current_seconds))


# 通常攻撃停止判定
func suppresses_default_attack() -> bool:
	return false


# 通常攻撃更新接続
func _bind_default_attack_refresh() -> void:
	if not suppresses_default_attack() or _refresh_processor == null:
		return
	_default_attack_refresh = EnemyEffectRefreshDefaultAttack.new()
	_default_attack_refresh.priority = priority
	_default_attack_refresh.disabled = true
	_default_attack_refresh.bind_owner(owner, effect_stack)
	_default_attack_refresh.bind_source(source)
	_default_attack_refresh.setup_refresh_trigger(_refresh_processor)
	_default_attack_refresh.bind()


# 発動Signal解除
func unbind_triggers() -> void:
	super.unbind_triggers()
	if _default_attack_refresh != null:
		_default_attack_refresh.unbind(false)
	_default_attack_refresh = null
	_battle_clock = null
	_refresh_processor = null


# 間隔発火数取得
func consume_interval(interval_seconds: int) -> int:
	if interval_seconds <= 0:
		return 0
	var accumulated := get_state_int("elapsed_seconds") + get_activation_elapsed_seconds() # 累積秒
	var count := int(accumulated / interval_seconds) # 発火数
	set_state("elapsed_seconds", accumulated % interval_seconds)
	return count
