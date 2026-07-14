class_name EnemyEffectOnSelfOrAdjacentDigestedRevive
extends EnemyEffect

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0
# 生存者必須
@export var require_survivor := true
# 自身を含む
@export var include_self := true

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.ADJACENT_DIGESTED): return
	var group := runtime.get_adjacent_objects() # 共有群
	if include_self: group.append(runtime.source)
	if not group.has(runtime.target): return
	var survivors := group.filter(func(enemy: Enemy) -> bool: return not enemy.is_Acided()) # 生存群
	if not require_survivor or not survivors.is_empty(): runtime.revive(runtime.target, recovery_rate)
