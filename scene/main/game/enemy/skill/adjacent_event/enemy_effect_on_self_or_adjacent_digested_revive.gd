class_name EnemyEffectOnSelfOrAdjacentDigestedRevive
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_ADJACENT_DIGESTED


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_ENEMIES

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0
# 生存者必須
@export var require_survivor := true
# 自身を含む
@export var include_self := true

# 効果適用
func apply() -> void:
	if not is_adjacent_digested_activation(): return
	var group := get_adjacent_objects() # 共有群
	if include_self: group.append(source)
	if not group.has(get_activation_target()): return
	var survivors := group.filter(func(enemy: Enemy) -> bool: return not enemy.is_Acided()) # 生存群
	if not require_survivor or not survivors.is_empty(): revive(get_activation_target(), recovery_rate)
