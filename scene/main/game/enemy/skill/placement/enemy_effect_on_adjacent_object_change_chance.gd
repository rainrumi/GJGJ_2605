class_name EnemyEffectOnAdjacentObjectChangeChance
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh_preprocess(self)


var enemies: Array[Enemy] = [] # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# 確率差分
@export_range(-1.0, 1.0, 0.01) var chance_delta := 0.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

# 効果適用
func apply() -> void:
	var targets := EnemyEffectTargetQuery.get_adjacent_objects(source, enemies) # 隣接対象
	if targets.size() < required_count: return
	for enemy in targets: EnemyEffectStatChanges.add_chance_delta(enemy, chance_delta)
