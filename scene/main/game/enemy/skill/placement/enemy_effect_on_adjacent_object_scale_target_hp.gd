class_name EnemyEffectOnAdjacentObjectScaleTargetHp
extends EnemyEffectOnRefresh



var enemies: Array[Enemy] = [] # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# HP倍率
@export var hp_multiplier := 1.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

# 効果適用
func apply() -> void:
	var targets := EnemyEffectTargetQuery.get_adjacent_objects(source, enemies) # 隣接対象
	if targets.size() < required_count:
		state.set_value("adjacent_ids", [])
		return
	var new_targets := EnemyEffectTracking.get_new_adjacent_objects(state, source, enemies) # 新規隣接対象
	for enemy in targets:
		var previous_maximum := enemy.data.hp.get_modified_maximum()
		EnemyEffectStatChanges.multiply_hp(source, enemy, hp_multiplier)
		if new_targets.has(enemy):
			enemy.heal_over_max(maxi(0, enemy.data.hp.get_modified_maximum() - previous_maximum))
