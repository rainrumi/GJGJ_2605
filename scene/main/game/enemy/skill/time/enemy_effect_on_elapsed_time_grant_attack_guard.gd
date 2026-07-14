class_name EnemyEffectOnElapsedTimeGrantAttackGuard
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH | ACTIVATION_PROGRESS_TIME

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 付与対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.SELF
# 無効回数
@export_range(1, 64, 1) var guard_count := 1
# 重複上限
@export_range(0, 64, 1) var stack_limit := 1
# 通常攻撃停止
@export var suppress_default_attack := false

# 効果適用
func apply() -> void:
	if is_refresh_activation(): set_default_attack_disabled(source, suppress_default_attack); return
	if not is_progress_time_activation(): return
	var count := consume_interval(interval_seconds) # 発火数
	for enemy in get_targets(target): add_attack_guards(enemy, mini(stack_limit, guard_count * count))
