class_name EnemyEffectOnOtherObjectScaleEffectByObjectCount
extends EnemyEffectOnRefreshPreprocess


var enemies: Array[Enemy] = [] # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []


# 倍増倍率取得
func get_object_count() -> int:
	return EnemyEffectTargetQuery.get_active_objects(enemies).size()


# 効果適用
func apply() -> void:
	var count := get_object_count()
	if count <= 0:
		return
	var multiplier := EnemyEffectValueCalculator.scale(source, float(count))
	for enemy in EnemyEffectTargetQuery.get_active_objects(enemies):
		if enemy != source:
			EnemyEffectStatChanges.multiply_effect(enemy, multiplier)
