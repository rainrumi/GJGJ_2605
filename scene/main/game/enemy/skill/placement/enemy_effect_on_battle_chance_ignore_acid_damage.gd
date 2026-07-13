class_name EnemyEffectOnBattleChanceIgnoreAcidDamage
extends EnemyEffect

# 無効率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 失敗率扱い
@export var invert_chance := false

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.BEFORE_ACID_DAMAGE) and context.target == context.source and context.roll(chance, invert_chance): context.damage = 0
