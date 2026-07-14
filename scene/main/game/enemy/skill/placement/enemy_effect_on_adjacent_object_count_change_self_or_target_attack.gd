class_name EnemyEffectOnAdjacentObjectCountChangeSelfOrTargetAttack
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var enemies: Array[Enemy] = [] # 効果依存
var stomach: StomachBoard # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()
	stomach = installer.get_stomach()


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	stomach = null

# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.SELF
# 攻撃差分
@export var attack_delta := 0
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 効果適用
func apply() -> void:
	var count := EnemyEffectTargetQuery.get_adjacent_objects(source, enemies).size() # 隣接数
	if count < minimum_count: return
	for enemy in EnemyEffectTargetQuery.get_targets(source, enemies, stomach, target): EnemyEffectStatChanges.add_attack_delta(source, enemy, attack_delta * count)
