class_name EnemyEffectOnAdjacentEnemyAcidRecoverVictim
extends EnemyEffect

# 隣接毎回復量
@export var recovery_per_adjacent := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.ADJACENT_ACID_DAMAGE) and runtime.get_adjacent_enemies().has(runtime.target): runtime.recover(runtime.target, recovery_per_adjacent * runtime.get_adjacent_enemies().size())
