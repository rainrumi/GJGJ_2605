class_name EnemyEffectOnDigestedRevive
extends EnemyEffect

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.DIGESTED) and runtime.target == runtime.source: runtime.revive(runtime.source, recovery_rate)
