class_name EnemyEffectOnStomachEdgeProgressTimeDealAcidDamage
extends EnemyEffectOnTimeProgressed


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_progress_time(self)


var enemies: Array[Enemy] = [] # 効果依存
var stomach: StomachBoard # 効果依存
var digestion_state: EnemyDigestionState # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 胃袋設定
func setup_stomach(value: StomachBoard) -> void:
	stomach = value


# 消化状態設定
func setup_digestion_state(value: EnemyDigestionState) -> void:
	digestion_state = value


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
