class_name EnemyEffectOnTouchAcidLineChangeAllAcidDamage
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var stomach: StomachBoard # 効果依存
var acid_modifiers: EnemyAcidDamageModifiers # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	stomach = installer.get_stomach()
	acid_modifiers = installer.get_acid_modifiers()


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
