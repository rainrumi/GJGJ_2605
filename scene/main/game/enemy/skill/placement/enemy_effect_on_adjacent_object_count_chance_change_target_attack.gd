class_name EnemyEffectOnAdjacentObjectCountChanceChangeTargetAttack
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

# 攻撃差分
@export var attack_delta := 0
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 当選時倍率
@export var chance_multiplier := 1.0

# 効果適用
func apply() -> void:
	var targets := EnemyEffectTargetQuery.get_adjacent_objects(source, enemies) # 隣接対象
	if targets.size() < minimum_count: return
	for enemy in targets:
		var value := attack_delta * targets.size() # 攻撃差分
		if EnemyEffectValueCalculator.roll(source, chance): value = roundi(float(value) * chance_multiplier)
		EnemyEffectStatChanges.add_attack_delta(source, enemy, value)
