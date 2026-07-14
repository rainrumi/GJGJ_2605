class_name EnemyEffectOnBattleChangeDigestIntervalByObjectCount
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var enemies: Array[Enemy] = [] # 効果依存
var digestion_interval: DigestionInterval # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	enemies = installer.get_enemies()
	digestion_interval = installer.get_digestion_interval()


# 依存関係解除
func clear_dependencies() -> void:
	enemies = []
	digestion_interval = null

# モノ毎秒差
@export var seconds_per_object := 0

# 効果適用
func apply() -> void:
	EnemyEffectWorldActions.add_interval_seconds(source, digestion_interval, seconds_per_object * EnemyEffectTargetQuery.get_active_objects(enemies).size())
