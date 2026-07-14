class_name EnemyEffectOnAdjacentStomachChangeDigestIntervalRate
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var stomach: StomachBoard # 効果依存
var digestion_interval: DigestionInterval # 効果依存


# 依存関係設定
func bind_dependencies(installer: EnemyEffectInstaller) -> void:
	stomach = installer.get_stomach()
	digestion_interval = installer.get_digestion_interval()


# 依存関係解除
func clear_dependencies() -> void:
	stomach = null
	digestion_interval = null

# 接触毎割合
@export var interval_delta_rate := 0.0

# 効果適用
func apply() -> void:
	EnemyEffectWorldActions.add_interval_rate(source, digestion_interval, interval_delta_rate * EnemyEffectTargetQuery.get_stomach_edge_contact_count(source, stomach))
