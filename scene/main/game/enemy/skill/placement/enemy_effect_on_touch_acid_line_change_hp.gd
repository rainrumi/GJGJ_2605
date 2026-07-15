class_name EnemyEffectOnTouchAcidLineChangeHp
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

# 効果適用
func apply() -> void:
	var active := 1 if EnemyEffectTargetQuery.get_acid_line_contact_count(source, stomach) > 0 else 0 # 接触状態
	var previous := get_state_int("active") # 直前状態
	set_state("active", active)
	EnemyEffectStatChanges.change_hp(source, source, hp_delta * (active - previous))
