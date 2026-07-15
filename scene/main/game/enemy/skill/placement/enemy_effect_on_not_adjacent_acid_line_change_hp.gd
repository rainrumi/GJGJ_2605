class_name EnemyEffectOnNotAdjacentAcidLineChangeHp
extends EnemyEffectOnRefresh



var stomach: StomachBoard # 効果依存


# 胃袋設定
func setup_stomach(value: StomachBoard) -> void:
	stomach = value


# 依存関係解除
func clear_dependencies() -> void:
	stomach = null

# HP差分
@export var hp_delta := 0
# HP倍率
@export var hp_multiplier := 1.0

# 効果適用
func apply() -> void:
	if EnemyEffectTargetQuery.get_acid_line_contact_count(source, stomach) == 0: EnemyEffectStatChanges.multiply_hp(source, source, hp_multiplier); EnemyEffectStatChanges.add_max_hp_delta(source, source, hp_delta, false)
