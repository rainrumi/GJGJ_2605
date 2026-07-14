class_name EnemyEffectOnDigestedReviveIfOtherObject
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_DIGESTED

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0

# 効果適用
func apply() -> void:
	if not is_digested_activation() or get_activation_target() != source: return
	if get_active_objects().any(func(enemy: Enemy) -> bool: return enemy != source): revive(source, recovery_rate)
