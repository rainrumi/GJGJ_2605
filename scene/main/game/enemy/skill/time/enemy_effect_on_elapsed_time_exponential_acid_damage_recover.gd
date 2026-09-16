class_name EnemyEffectOnElapsedTimeExponentialAcidDamageRecover
extends EnemyEffectOnTimeProgressed


var digestion_state: EnemyDigestionState # 効果依存
var digestion_interval: DigestionInterval # 効果依存


# 消化状態設定
func setup_digestion_state(value: EnemyDigestionState) -> void:
	digestion_state = value


# 消化間隔設定
func setup_digestion_interval(value: DigestionInterval) -> void:
	digestion_interval = value


# 依存関係解除
func clear_dependencies() -> void:
	digestion_state = null
	digestion_interval = null


# 発動間隔
@export_range(1, 86400, 1) var interval_seconds := 60
# 累乗の底
@export_range(1.0, 10.0, 0.1) var exponent_base := 3.0
# 消化間隔の除数（分）
@export_range(1, 1440, 1) var interval_divisor_minutes := 15


# 効果適用
func apply() -> void:
	var count := consume_interval(interval_seconds)
	if count <= 0 or source == null:
		return
	var interval_minutes := 1.0
	if digestion_interval != null:
		interval_minutes = float(digestion_interval.resolve(1800)) / 60.0
	var damage := roundi(pow(exponent_base, interval_minutes / float(interval_divisor_minutes)))
	for _index in range(count):
		if source.is_Acided():
			break
		if source.take_acid_damage(damage):
			if digestion_state != null:
				digestion_state.register(source)
			break
		source.current_hp = source.max_hp
