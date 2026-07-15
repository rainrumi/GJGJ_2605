class_name EnemyEffectOnProgressTimeChangeAttackByObjectCount
extends EnemyEffectOnTimeProgressed



var enemies: Array[Enemy] = [] # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# モノ毎攻撃
@export var attack_per_object := 0
# 自身を含む
@export var include_self := true

# 効果適用
func apply() -> void:
	var count := EnemyEffectTargetQuery.get_active_objects(enemies).size() # モノ数
	if not include_self: count = maxi(0, count - 1)
	source.add_damage(attack_per_object * count - source.get_damage())
