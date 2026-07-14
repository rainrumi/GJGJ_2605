class_name EnemyEffectOnBattleChangeMaxHpByEmptyCell
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

# マス毎最大HP
@export var max_hp_delta_per_cell := 0

# 効果適用
func apply() -> void:
	EnemyEffectStatChanges.add_max_hp_delta(source, source, max_hp_delta_per_cell * EnemyEffectTargetQuery.get_empty_cell_count(enemies, stomach), false)
