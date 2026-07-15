class_name EnemyEffectOnDigested
extends EnemyEffectWithTimeData

var _digestion_targets: Array[Enemy] = [] # 消化Signal対象


# 消化Trigger設定
func setup_digestion_triggers(enemies: Array[Enemy], _state: EnemyDigestionState) -> void:
	_digestion_targets.assign(enemies)


# 発動Signal接続
func bind() -> void:
	for enemy in _digestion_targets:
		if enemy == null:
			continue
		var callback := _on_digestion_resolved.bind(enemy) # 対象付き受信
		connect_trigger(enemy.data.stomach_status.digestion_resolved, callback)


# 消化結果受信
func _on_digestion_resolved(
	damage: int,
	overkill: int,
	elapsed_seconds: int,
	current_seconds: int,
	digested_data: Array[EnemyData],
	target_enemy: Enemy
) -> void:
	queue_activation(_create_digestion_data(
		target_enemy,
		damage,
		overkill,
		elapsed_seconds,
		current_seconds,
		digested_data
	))


# 消化発動値作成
func _create_digestion_data(
	target_enemy: Enemy,
	damage: int,
	overkill: int,
	elapsed_seconds: int,
	current_seconds: int,
	digested_data: Array[EnemyData]
) -> DigestionActivationData:
	var digested_enemies: Array[Enemy] = [] # 消化Node一覧
	for enemy in _digestion_targets:
		if enemy != null and digested_data.has(enemy.data):
			digested_enemies.append(enemy)
	var data := DigestedActivationData.new() # 消化発動値
	data.setup(target_enemy, damage, overkill, elapsed_seconds, current_seconds, digested_enemies)
	return data


# 発動Signal解除
func unbind_triggers() -> void:
	super.unbind_triggers()
	_digestion_targets.clear()


# 消化後発動許可
func can_activate_when_owner_digested() -> bool:
	return true


# 消化発動値取得
func get_digestion_activation() -> DigestionActivationData:
	return get_activation_data() as DigestionActivationData


# 発動対象取得
func get_activation_target() -> Enemy:
	var data := get_digestion_activation() # 消化発動値
	return data.target_enemy if data != null else null


# 指定発動対象取得
func get_activation_target_from(data: EnemyEffectActivationData) -> Enemy:
	var digestion_data := data as DigestionActivationData # 消化発動値
	return digestion_data.target_enemy if digestion_data != null else null


# 発動ダメージ取得
func get_activation_damage() -> int:
	var data := get_digestion_activation() # 消化発動値
	return data.damage if data != null else 0


# 超過ダメージ取得
func get_activation_overkill_damage() -> int:
	var data := get_digestion_activation() # 消化発動値
	return data.overkill_damage if data != null else 0


# 消化済み一覧取得
func get_activation_digested_enemies() -> Array[Enemy]:
	var data := get_digestion_activation() # 消化発動値
	return data.digested_enemies if data != null else []


# 発動固有値取得
func get_event_value(source_type: ValueSource, data: EnemyEffectActivationData) -> int:
	var digestion_data := data as DigestionActivationData # 消化発動値
	if source_type == ValueSource.TAKEN_DAMAGE:
		return digestion_data.damage if digestion_data != null else 0
	if source_type == ValueSource.OVERKILL_DAMAGE:
		return digestion_data.overkill_damage if digestion_data != null else 0
	return 0
