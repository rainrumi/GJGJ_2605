class_name EnemySkill
extends Resource

# 優先度
@export var priority: int
# 効果一覧
@export var effects: Array[EnemyEffect] = []


# 有効効果取得
func get_effects() -> Array[EnemyEffect]:
	var active_effects: Array[EnemyEffect] = [] # 有効効果
	for effect in effects:
		if effect != null and effect.enabled:
			active_effects.append(effect)
	active_effects.sort_custom(func(a: EnemyEffect, b: EnemyEffect) -> bool:
		return a.priority < b.priority
	)
	return active_effects


# 効果有無
func has_effects() -> bool:
	return not get_effects().is_empty()
