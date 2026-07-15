class_name EnemyEffectOnRefreshPreprocess
extends EnemyNodeEffect

var _refresh_processor: EnemyEffectRefreshProcessor # 更新Signal元


# 更新前Trigger設定
func setup_refresh_trigger(processor: EnemyEffectRefreshProcessor) -> void:
	_refresh_processor = processor


# 発動Signal接続
func bind() -> void:
	if _refresh_processor != null:
		connect_trigger(_refresh_processor.preprocess_requested, queue_activation)


# 発動Signal解除
func unbind_triggers() -> void:
	super.unbind_triggers()
	_refresh_processor = null
