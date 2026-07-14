class_name EnemyEffectOnAdjacentObjectDigestedRevive
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_ADJACENT_DIGESTED

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0
# 復活対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply() -> void:
	if is_adjacent_digested_activation() and get_targets(target).has(get_activation_target()): revive(get_activation_target(), recovery_rate)
