class_name EnemyEffectOnStomachEdgeProgressTimeDealAcidDamage
extends EnemyEffect

# ダメージ
@export var damage := 0
# 対象選択
@export var selection: EnemyEffect.TargetSelection = EnemyEffect.TargetSelection.RANDOM_ONE
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ALL_OBJECTS

# 効果適用
func apply() -> void:
	if not is_progress_time_activation() or get_stomach_edge_contact_count() == 0: return
	var targets := get_targets(target) # 対象一覧
	if targets.is_empty(): return
	if selection == TargetSelection.RANDOM_ONE: targets = [targets.pick_random()]
	elif selection == TargetSelection.LOWEST_HP: targets.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.get_current_hp() < b.get_current_hp()); targets = [targets[0]]
	for enemy in targets: deal_acid_damage(enemy, damage)
