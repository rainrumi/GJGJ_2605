class_name EnemyEffectOnDigested
extends EnemyEffectOnTimeProgressed


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
