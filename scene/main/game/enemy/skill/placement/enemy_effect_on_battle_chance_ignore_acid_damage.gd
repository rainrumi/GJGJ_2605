class_name EnemyEffectOnBattleChanceIgnoreAcidDamage
extends EnemyEffectOnSelfBeforeAcidDamage


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_before_acid_damage(self)

# 無効率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 失敗率扱い
@export var invert_chance := false

# 発動条件判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	return super.accepts_activation(data) and EnemyEffectValueCalculator.roll(source, chance, invert_chance)


# 効果適用
func apply() -> void:
	set_activation_damage(0)
