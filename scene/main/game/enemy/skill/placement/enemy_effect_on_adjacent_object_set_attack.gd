class_name EnemyEffectOnAdjacentObjectSetAttack
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var enemies: Array[Enemy] = [] # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# 指定攻撃力
@export var attack := 0
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 効果適用
func apply() -> void:
	if EnemyEffectTargetQuery.get_adjacent_objects(source, enemies).size() >= minimum_count:
		EnemyEffectStatChanges.set_attack(source, source, attack)
