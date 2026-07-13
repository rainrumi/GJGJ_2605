class_name EnemyEffectOnDigestionCountDealAllAcidDamage
extends EnemyEffect

# 必要消化数
@export_range(1, 10000, 1) var required_count := 1
# ダメージ
@export var damage := 0
# 攻撃回数
@export_range(1, 64, 1) var hit_count := 1
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ALL_OBJECTS

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.ANY_DIGESTED): return
	var count := context.get_state_int("digestion_count") + context.digested_enemies.size() # 消化数
	var triggers := int(count / required_count) # 発火数
	context.set_state("digestion_count", count % required_count)
	for enemy in context.get_targets(target): context.deal_acid_damage(enemy, damage, hit_count * triggers)
