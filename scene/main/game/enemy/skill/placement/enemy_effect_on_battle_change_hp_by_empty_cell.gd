class_name EnemyEffectOnBattleChangeHpByEmptyCell
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var enemies: Array[Enemy] = [] # 効果依存
var stomach: StomachBoard # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 胃袋設定
func setup_stomach(value: StomachBoard) -> void:
	stomach = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	stomach = null

# マス毎HP
@export var hp_delta_per_cell := 0

# 効果適用
func apply() -> void:
	EnemyEffectStatChanges.change_hp(source, source, hp_delta_per_cell * (EnemyEffectTargetQuery.get_empty_cell_count(enemies, stomach) - get_state_int("empty_count"))); set_state("empty_count", EnemyEffectTargetQuery.get_empty_cell_count(enemies, stomach))
