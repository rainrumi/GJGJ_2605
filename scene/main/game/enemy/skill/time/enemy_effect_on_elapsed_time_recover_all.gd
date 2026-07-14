class_name EnemyEffectOnElapsedTimeRecoverAll
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 回復量
@export var recovery := 0
# 自身を含む
@export var include_self := true
# 通常攻撃停止
@export var suppress_default_attack := false

# 効果適用
func apply() -> void:
	if is_refresh_activation(): set_default_attack_disabled(source, suppress_default_attack); return
	if not is_progress_time_activation(): return
	var count := consume_interval(interval_seconds) # 発火数
	for enemy in get_active_objects():
		if include_self or enemy != source: recover(enemy, recovery * count)
