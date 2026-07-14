class_name EnemyEffectOnElapsedTimeTriggerAdjacentAcidDamage
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
