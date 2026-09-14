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
	if not source.is_active_in_stomach() or EnemyEffectTargetQuery.get_acid_line_contact_count(source, stomach) > 0:
		set_state("active", 0)
		return
	if get_state_int("active") == 0:
		var scaled_delta := roundi(EnemyEffectValueCalculator.scale(source, float(hp_delta)))
		var scaled_multiplier := EnemyEffectValueCalculator.scale(source, hp_multiplier)
		var increased_maximum := roundi(float(source.max_hp + scaled_delta) * scaled_multiplier) - source.max_hp
		source.heal_over_max(maxi(0, increased_maximum))
	set_state("active", 1)
	EnemyEffectStatChanges.multiply_hp(source, source, hp_multiplier)
	EnemyEffectStatChanges.add_max_hp_delta(source, source, hp_delta, false)
