class_name EnemyEffectOnAcidDamageTransfer
extends EnemyEffectOnSelfBeforeAcidDamage



var enemies: Array[Enemy] = [] # 効果依存
var digestion_state: EnemyDigestionState # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 消化状態設定
func setup_digestion_state(value: EnemyDigestionState) -> void:
	digestion_state = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	digestion_state = null

# 譲渡率
@export_range(0.0, 1.0, 0.01) var transfer_rate := 0.0
# 対象選択
@export var selection: EnemyEffect.AdjacentSelection = EnemyEffect.AdjacentSelection.LOWEST_HP
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 効果適用
func apply() -> void:
	var targets := EnemyEffectTargetQuery.get_adjacent_objects(source, enemies) # 譲渡対象
	if targets.size() < minimum_count: return
	if selection == AdjacentSelection.LOWEST_HP: targets.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.get_current_hp() < b.get_current_hp()); targets = [targets[0]]
	elif selection == AdjacentSelection.RANDOM_ONE: targets = [targets.pick_random()]
	var split := roundi(float(get_activation_damage()) * transfer_rate / float(targets.size())) # 譲渡値
	for enemy in targets: EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, enemy, split)
	set_activation_damage(maxi(0, get_activation_damage() - split * targets.size()))
