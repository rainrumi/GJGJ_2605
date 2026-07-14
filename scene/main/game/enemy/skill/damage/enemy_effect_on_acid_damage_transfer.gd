class_name EnemyEffectOnAcidDamageTransfer
extends EnemyEffect

# 譲渡率
@export_range(0.0, 1.0, 0.01) var transfer_rate := 0.0
# 対象選択
@export var selection: EnemyEffect.AdjacentSelection = EnemyEffect.AdjacentSelection.LOWEST_HP
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.BEFORE_ACID_DAMAGE) or runtime.target != runtime.source: return
	var targets := runtime.get_adjacent_objects() # 譲渡対象
	if targets.size() < minimum_count: return
	if selection == AdjacentSelection.LOWEST_HP: targets.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.get_current_hp() < b.get_current_hp()); targets = [targets[0]]
	elif selection == AdjacentSelection.RANDOM_ONE: targets = [targets.pick_random()]
	var split := roundi(float(runtime.damage) * transfer_rate / float(targets.size())) # 譲渡値
	for enemy in targets: runtime.deal_acid_damage(enemy, split)
	runtime.damage = maxi(0, runtime.damage - split * targets.size())
