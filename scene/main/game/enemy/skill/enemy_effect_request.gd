class_name EnemyEffectRequest
extends RefCounted

var effect: EnemyEffect # 実行効果
var activation_data: EnemyEffectActivationData # 発動時値
var priority := 0 # 実行優先度
var sequence := 0 # 受付順


# 要求初期化
func setup(
	target_effect: EnemyEffect,
	data: EnemyEffectActivationData,
	request_priority: int,
	request_sequence: int
) -> void:
	effect = target_effect
	activation_data = data
	priority = request_priority
	sequence = request_sequence


# 要求実行
func execute() -> void:
	if effect == null or not effect.enabled:
		return
	effect.begin_activation(activation_data)
	effect.apply()
	effect.end_activation()
