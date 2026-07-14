class_name EnemyEffectOnTouchAcidLineChangeDigestIntervalSeconds
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

# 秒差分
@export var interval_delta_seconds := 0

# 効果適用
func apply() -> void:
	if EnemyEffectTargetQuery.get_acid_line_contact_count(source, stomach) > 0: EnemyEffectWorldActions.add_interval_seconds(source, digestion_interval, interval_delta_seconds)
