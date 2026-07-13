class_name EnemyEffectOnAcidDamageAttack
extends EnemyEffect

# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.AFTER_ACID_DAMAGE) and context.target == context.source: context.attack_player(fixed_damage if fixed_damage > 0 else context.source.get_damage(), attack_count)
