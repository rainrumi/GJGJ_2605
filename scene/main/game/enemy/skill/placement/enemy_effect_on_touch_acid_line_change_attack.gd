class_name EnemyEffectOnTouchAcidLineChangeAttack
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var stomach: StomachBoard # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	stomach = installer.get_stomach()


# 依存関係解除
func clear_dependencies() -> void:
	stomach = null

# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply() -> void:
	if EnemyEffectTargetQuery.get_acid_line_contact_count(source, stomach) > 0: EnemyEffectStatChanges.add_attack_delta(source, source, attack_delta)
