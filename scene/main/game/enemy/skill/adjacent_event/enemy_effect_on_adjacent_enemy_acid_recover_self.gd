class_name EnemyEffectOnAdjacentEnemyAcidRecoverSelf
extends EnemyEffectOnAdjacentAcidDamage


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_adjacent_acid_damage(self)


var enemies: Array[Enemy] = [] # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []

# 隣接毎回復量
@export var recovery_per_adjacent := 0

# 効果適用
func apply() -> void:
	EnemyEffectBattleActions.recover(source, source, recovery_per_adjacent * EnemyEffectTargetQuery.get_adjacent_enemies(source, enemies).size())
