class_name EnemyEffectLegacyActivationData
extends EnemyEffectActivationData

var execution: EnemyEffectRuntime # 移行用実行値


# 移行値初期化
func _init(value: EnemyEffectRuntime = null) -> void:
	execution = value


# 発動値検証
func is_valid() -> bool:
	return execution != null and execution.source != null and is_instance_valid(execution.source)
