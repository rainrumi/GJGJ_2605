class_name EnemyEffectOnElapsedTimeTriggerAdjacentAcidDamage
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

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 消化回数
@export_range(1, 64, 1) var hit_count := 1
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply() -> void:
	var count := consume_interval(interval_seconds) # 発火数
	for enemy in EnemyEffectTargetQuery.get_targets(source, enemies, stomach, target): EnemyEffectBattleActions.deal_acid_damage(self, digestion_state, enemy, (digestion_state.last_acid_damage if digestion_state != null else 0), hit_count * count)
