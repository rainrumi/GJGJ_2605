class_name EnemyEffectOnAdjacentObjectTransferAcidDamage
extends EnemyEffect

# 譲渡率
@export_range(0.0, 1.0, 0.01) var transfer_rate := 0.0
# 対象選択
@export var selection: EnemyEffect.AdjacentSelection = EnemyEffect.AdjacentSelection.ALL
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.BEFORE_ACID_DAMAGE) or context.target != context.source: return
	var targets := context.get_adjacent_objects() # 譲渡対象
	if targets.size() < minimum_count: return
	if selection == AdjacentSelection.LOWEST_HP: targets.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.get_current_hp() < b.get_current_hp()); targets = [targets[0]]
	elif selection == AdjacentSelection.RANDOM_ONE: targets = [targets.pick_random()]
	var amount := roundi(float(context.damage) * transfer_rate / float(targets.size())) # 譲渡値
	for enemy in targets: context.deal_acid_damage(enemy, amount)
	context.damage = maxi(0, context.damage - amount * targets.size())
