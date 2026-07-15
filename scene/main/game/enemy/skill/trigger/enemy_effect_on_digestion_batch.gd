class_name EnemyEffectOnDigestionBatch
extends EnemyEffectOnDigested

var _digestion_state: EnemyDigestionState # 一括Signal元


# 消化Trigger設定
func setup_digestion_triggers(enemies: Array[Enemy], state: EnemyDigestionState) -> void:
	super.setup_digestion_triggers(enemies, state)
	_digestion_state = state


# 発動Signal接続
func bind() -> void:
	if _digestion_state != null:
		connect_trigger(_digestion_state.batch_completed, _on_batch_completed)


# 一括消化受信
func _on_batch_completed(
	elapsed_seconds: int,
	current_seconds: int,
	digested_data: Array[EnemyData]
) -> void:
	var data := _create_digestion_data(
		null,
		0,
		0,
		elapsed_seconds,
		current_seconds,
		digested_data
	) # 一括発動値
	queue_activation(data)


# 発動Signal解除
func unbind_triggers() -> void:
	super.unbind_triggers()
	_digestion_state = null
