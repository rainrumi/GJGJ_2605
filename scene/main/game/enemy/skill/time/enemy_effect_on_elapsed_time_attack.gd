class_name EnemyEffectOnElapsedTimeAttack
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0
# 通常攻撃停止
@export var suppress_default_attack := false
# ダメージ参照元
@export var damage_source: EnemyEffect.ValueSource = EnemyEffect.ValueSource.SELF_ATTACK

# 効果適用
func apply() -> void:
	if is_refresh_activation(): set_default_attack_disabled(source, suppress_default_attack); return
	if not is_progress_time_activation(): return
	var triggers := consume_interval(interval_seconds) # 発火数
	attack_player(resolve_value(damage_source, fixed_damage), attack_count * triggers)
