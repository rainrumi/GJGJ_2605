class_name EnemyEffectOnDigestedReviveIfOtherObject
extends EnemyEffect

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.DIGESTED) or runtime.target != runtime.source: return
	if runtime.get_active_objects().any(func(enemy: Enemy) -> bool: return enemy != runtime.source): runtime.revive(runtime.source, recovery_rate)
