class_name EnemyEffectInheritance
extends RefCounted

var _effects: Dictionary = {} # 継承効果一覧


# 継承状態初期化
func reset() -> void:
	for enemy in _effects.keys():
		for effect in get_effects(enemy):
			if effect != null:
				effect.unbind()
	_effects.clear()


# 効果継承
func inherit(target: Enemy, source: Enemy) -> void:
	if target == null or source == null:
		return
	var values: Array[EnemyEffect] = get_effects(target) # 継承一覧
	for effect in source.get_enemy_effects():
		if effect != null:
			values.append(effect.duplicate(true) as EnemyEffect)
	_effects[target] = values


# 継承効果取得
func get_effects(enemy: Enemy) -> Array[EnemyEffect]:
	var values: Array[EnemyEffect] = [] # 継承一覧
	if _effects.has(enemy):
		values.append_array(_effects[enemy])
	return values
