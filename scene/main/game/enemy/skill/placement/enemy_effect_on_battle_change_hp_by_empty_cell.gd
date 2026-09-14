class_name EnemyEffectOnBattleChangeHpByEmptyCell
extends EnemyEffectOnRefresh



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

# 最大HP補正確定前の上限外回復
@export var heal_over_maximum := false

# 効果適用
func apply() -> void:
	if not source.is_active_in_stomach():
		set_state("empty_count", 0)
		return
	var empty_count := EnemyEffectTargetQuery.get_empty_cell_count(enemies, stomach)
	EnemyEffectStatChanges.change_hp(
		source, source, hp_delta_per_cell * (empty_count - get_state_int("empty_count")), heal_over_maximum
	)
	set_state("empty_count", empty_count)
