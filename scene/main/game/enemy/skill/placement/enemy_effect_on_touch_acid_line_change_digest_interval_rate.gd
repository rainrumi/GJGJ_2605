class_name EnemyEffectOnTouchAcidLineChangeDigestIntervalRate
extends EnemyEffect


# 発動Signal接続
func bind_triggers(installer: EnemyEffectInstaller) -> void:
	installer.connect_refresh(self)


var stomach: StomachBoard # 効果依存
var digestion_interval: DigestionInterval # 効果依存


# 胃袋設定
func setup_stomach(value: StomachBoard) -> void:
	stomach = value


# 消化間隔設定
func setup_digestion_interval(value: DigestionInterval) -> void:
	digestion_interval = value


# 依存関係解除
func clear_dependencies() -> void:
	stomach = null
	digestion_interval = null

# 割合差分
@export var interval_delta_rate := 0.0

# 効果適用
func apply() -> void:
	if EnemyEffectTargetQuery.get_acid_line_contact_count(source, stomach) > 0: EnemyEffectWorldActions.add_interval_rate(source, digestion_interval, interval_delta_rate)
