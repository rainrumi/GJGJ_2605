class_name EnemyEffectOnAcidDamageAtMostTakeScaledAcidDamage
extends EnemyEffectOnSelfAfterAcidDamage

var digestion_state: EnemyDigestionState
var _applying_scaled_damage := false

@export_range(1, 10000, 1) var maximum_damage := 10
@export_range(1, 10000, 1) var damage_multiplier := 1000


func setup_digestion_state(value: EnemyDigestionState) -> void:
	digestion_state = value


func clear_dependencies() -> void:
	digestion_state = null


func can_request(data: EnemyEffectActivationData) -> bool:
	return not _applying_scaled_damage and super.can_request(data)


func accepts_activation(data: EnemyEffectActivationData) -> bool:
	return super.accepts_activation(data) \
		and get_activation_damage_from(data) > 0 \
		and get_activation_damage_from(data) <= maximum_damage


func apply() -> void:
	_applying_scaled_damage = true
	EnemyEffectBattleActions.deal_acid_damage(
		self,
		digestion_state,
		source,
		get_activation_damage() * damage_multiplier,
		1,
		true
	)
	_applying_scaled_damage = false
