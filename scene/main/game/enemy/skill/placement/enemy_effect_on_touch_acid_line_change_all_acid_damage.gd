class_name EnemyEffectOnTouchAcidLineChangeAllAcidDamage
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var stomach: StomachBoard # 効果依存
var acid_modifiers: EnemyAcidDamageModifiers # 効果依存


# 胃袋設定
func setup_stomach(value: StomachBoard) -> void:
	stomach = value


# 消化補正設定
func setup_acid_modifiers(value: EnemyAcidDamageModifiers) -> void:
	acid_modifiers = value


# 依存関係解除
func clear_dependencies() -> void:
	stomach = null
	acid_modifiers = null

# ダメージ差分
@export var damage_delta := 0
# ダメージ倍率
@export var damage_multiplier := 1.0

# 効果適用
func apply() -> void:
	if EnemyEffectTargetQuery.get_acid_line_contact_count(source, stomach) > 0: EnemyEffectWorldActions.add_global_acid_damage(source, acid_modifiers, damage_delta, damage_multiplier)
