class_name EnemyEffectOnDamage
extends EnemyEffect


# 被弾発動値取得
func get_damage_activation() -> DamageActivationData:
	return get_activation_data() as DamageActivationData


# 指定被弾値取得
func get_damage_activation_from(data: EnemyEffectActivationData) -> DamageActivationData:
	return data as DamageActivationData


# 発動対象取得
func get_activation_target() -> Enemy:
	var data := get_damage_activation() # 被弾発動値
	return data.target_enemy if data != null else null


# 指定発動対象取得
func get_activation_target_from(data: EnemyEffectActivationData) -> Enemy:
	var damage_data := get_damage_activation_from(data) # 被弾発動値
	return damage_data.target_enemy if damage_data != null else null


# 発動ダメージ取得
func get_activation_damage() -> int:
	var data := get_damage_activation() # 被弾発動値
	return data.amount if data != null else 0


# 指定発動値取得
func get_activation_damage_from(data: EnemyEffectActivationData) -> int:
	var damage_data := get_damage_activation_from(data) # 被弾発動値
	return damage_data.amount if damage_data != null else 0


# 発動ダメージ設定
func set_activation_damage(value: int) -> void:
	var data := get_damage_activation() # 被弾発動値
	if data != null:
		data.set_amount(value)


# 超過ダメージ取得
func get_activation_overkill_damage() -> int:
	var data := get_damage_activation() # 被弾発動値
	return data.overkill_amount if data != null else 0


# 発動固有値取得
func get_event_value(source_type: ValueSource, data: EnemyEffectActivationData) -> int:
	var damage_data := get_damage_activation_from(data) # 被弾発動値
	if source_type == ValueSource.TAKEN_DAMAGE:
		return damage_data.amount if damage_data != null else 0
	if source_type == ValueSource.OVERKILL_DAMAGE:
		return damage_data.overkill_amount if damage_data != null else 0
	return 0
