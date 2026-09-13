class_name EnemyEffectOnAttackChanceScaleDamage
extends EnemyEffect


@export var attack_multiplier := 1.0
@export_range(0.0, 1.0, 0.01) var chance := 1.0


func get_damage_multiplier(source: Enemy) -> float:
	if not EnemyEffectValueCalculator.roll(source, chance):
		return 1.0
	return EnemyEffectValueCalculator.scale(source, attack_multiplier)
