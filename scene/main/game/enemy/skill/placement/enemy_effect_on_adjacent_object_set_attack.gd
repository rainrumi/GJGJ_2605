class_name EnemyEffectOnAdjacentObjectSetAttack
extends EnemyEffect

# 指定攻撃力
@export var attack := 0
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH) and runtime.get_adjacent_objects().size() >= minimum_count:
		runtime.set_attack(runtime.source, attack)
