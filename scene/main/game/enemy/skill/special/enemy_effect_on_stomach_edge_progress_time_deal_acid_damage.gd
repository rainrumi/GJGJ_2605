class_name EnemyEffectOnStomachEdgeProgressTimeDealAcidDamage
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_progress_time(self)


var enemies: Array[Enemy] = [] # 効果依存
var stomach: StomachBoard # 効果依存
var digestion_state: EnemyDigestionState # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()
	stomach = installer.get_stomach()
	digestion_state = installer.get_digestion_state()


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	stomach = null
	digestion_state = null

# ダメージ
@export var damage := 0
# 対象選択
@export var selection: EnemyEffect.TargetSelection = EnemyEffect.TargetSelection.RANDOM_ONE
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ALL_OBJECTS

# 効果適用
func apply() -> void:
	if EnemyEffectTargetQuery.get_stomach_edge_contact_count(source, stomach) == 0: return
	var targets := EnemyEffectTargetQuery.get_targets(source, enemies, stomach, target) # 対象一覧
	if targets.is_empty(): return
	if selection == TargetSelection.RANDOM_ONE: targets = [targets.pick_random()]
	elif selection == TargetSelection.LOWEST_HP: targets.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.get_current_hp() < b.get_current_hp()); targets = [targets[0]]
	for enemy in targets: EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, enemy, damage)
