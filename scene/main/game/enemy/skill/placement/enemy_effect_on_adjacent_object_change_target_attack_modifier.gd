class_name EnemyEffectOnAdjacentObjectChangeTargetAttackModifier
extends EnemyEffectOnRefresh



var enemies: Array[Enemy] = [] # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply() -> void:
	for enemy in EnemyEffectTargetQuery.get_adjacent_objects(source, enemies):
		EnemyEffectStatChanges.add_attack_delta(source, enemy, attack_delta)
