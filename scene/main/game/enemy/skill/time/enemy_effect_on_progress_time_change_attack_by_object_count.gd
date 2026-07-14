class_name EnemyEffectOnProgressTimeChangeAttackByObjectCount
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_progress_time(self)


var enemies: Array[Enemy] = [] # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()


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
