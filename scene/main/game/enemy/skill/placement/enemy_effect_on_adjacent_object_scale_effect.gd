class_name EnemyEffectOnAdjacentObjectScaleEffect
extends EnemyEffectOnRefreshPreprocess



var enemies: Array[Enemy] = [] # 効果…1035 tokens truncated…果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# 効果倍率
@export var effect_multiplier := 1.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

# 各対象に必要な接触辺数
@export_range(1, 64, 1) var required_contact_count := 1

# 効果適用
func apply() -> void:
	var targets: Array[Enemy] = []
	for enemy in EnemyEffectTargetQuery.get_adjacent_objects(source, enemies):
		if _get_contact_count(enemy) >= required_contact_count:
			targets.append(enemy)
	if targets.size() < required_count: return
	for enemy in targets: EnemyEffectStatChanges.multiply_effect(enemy, effect_multiplier)


func _get_contact_count(target: Enemy) -> int:
	var target_cells := target.get_occupied_cells(target.stomach_cell)
	var count := 0
	for cell in source.get_occupied_cells(source.stomach_cell):
		for direction: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			if target_cells.has(cell + direction):
				count += 1
	return count
