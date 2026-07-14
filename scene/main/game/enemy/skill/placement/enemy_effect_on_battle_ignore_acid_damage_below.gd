class_name EnemyEffectOnBattleIgnoreAcidDamageBelow
extends EnemyEffectOnSelfBeforeAcidDamage


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_before_acid_damage(self)

# 閾値
@export var threshold := 0
# 閾値参照元
@export var threshold_source: EnemyEffect.ValueSource = EnemyEffect.ValueSource.FIXED

# 発動条件判定
func accepts_activation(data: EnemyEffectActivationData) -> bool:
	return super.accepts_activation(data) \
		and get_activation_damage_from(data) < resolve_value_from(threshold_source, threshold, data)


# 効果適用
func apply() -> void:
	set_activation_damage(0)
