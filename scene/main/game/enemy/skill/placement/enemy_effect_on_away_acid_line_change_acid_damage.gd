class_name EnemyEffectOnAwayAcidLineChangeAcidDamage
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var stomach: StomachBoard # 効果依存


# 胃袋設定
func setup_stomach(value: StomachBoard) -> void:
	stomach = value


# 依存関係解除
func clear_dependencies() -> void:
	stomach = null

# ダメージ差分
@export var acid_damage_delta := 0

# 効果適用
func apply() -> void:
	if EnemyEffectTargetQuery.get_acid_line_contact_count(source, stomach) == 0: EnemyEffectStatChanges.add_acid_damage_delta(source, source, acid_damage_delta)
