class_name EnemyEffectOnBattleChangeDigestIntervalByObjectCount
extends EnemyEffectOnRefresh



var enemies: Array[Enemy] = [] # 効果依存
var digestion_interval: DigestionInterval # 効果依存


# 敵一覧設定
func setup_enemies(value: Array[Enemy]) -> void:
	enemies = value


# 消化間隔設定
func setup_digestion_interval(value: DigestionInterval) -> void:
	digestion_interval = value


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	digestion_interval = null

# モノ毎秒差
@export var seconds_per_object := 0

# 効果適用
func apply() -> void:
	EnemyEffectWorldActions.add_interval_seconds(source, digestion_interval, seconds_per_object * EnemyEffectTargetQuery.get_active_objects(enemies).size())
