class_name EnemyEffect
extends Resource

enum EffectTarget {
	SELF,
	ADJACENT_OBJECTS,
	ADJACENT_ENEMIES,
	ALL_OBJECTS,
	ALL_ENEMIES,
	ACID_LINE_OBJECTS,
}

enum AdjacentSelection {
	ALL,
	EVEN_SPLIT,
	LOWEST_HP,
	RANDOM_ONE,
}

enum TargetSelection {
	ALL,
	RANDOM_ONE,
	LOWEST_HP,
}

enum SpawnArea {
	SAME_CELLS,
	EMPTY_STOMACH,
	EMPTY_ADJACENT,
	OUTSIDE_STOMACH,
}

enum ValueSource {
	FIXED,
	SELF_CURRENT_HP,
	SELF_MAX_HP,
	SELF_ATTACK,
	TAKEN_DAMAGE,
	OVERKILL_DAMAGE,
	DIGESTED_MINUTES,
	LOST_HP,
	INHERITED_VALUE,
}

# 適用順
@export var priority :int = 0
# 有効状態
@export var enabled :bool = true
var state := EnemyEffectState.new() # 個体効果状態
var _activation_data: EnemyEffectActivationData # 発動時値
var owner: EnemyData # 効果所有データ
var effect_stack: EnemyEffectStack # 効果スタック


# 所有データ設定
func bind_owner(owner_data: EnemyData, stack: EnemyEffectStack) -> void:
	owner = owner_data
	effect_stack = stack


# 発動Signal接続
func bind() -> void:
	pass


# 発動Signal解除
func unbind_triggers() -> void:
	pass


# 依存関係解除
func clear_dependencies() -> void:
	pass


# 発動開始
func begin_activation(data: EnemyEffectActivationData) -> void:
	_activation_data = data


# 発動値取得
func get_activation_data() -> EnemyEffectActivationData:
	return _activation_data


# 発動終了
func end_activation() -> void:
	_activation_data = null


# 要求可能判定
func can_request(data: EnemyEffectActivationData) -> bool:
	if not enabled or owner == null or data == null or not data.is_valid():
		return false
	if not owner.skills_enabled:
		return false
	var lifecycle_allowed := not owner.stomach_status.is_digested or can_activate_when_owner_digested()
	return lifecycle_allowed and accepts_activation(data)


# 消化後発動可否
func can_activate_when_owner_digested() -> bool:
	return false


# 発動条件判定
func accepts_activation(_data: EnemyEffectActivationData) -> bool:
	return true


# 接続解除
func unbind(clear_state := true) -> void:
	_activation_data = null
	unbind_triggers()
	clear_dependencies()
	owner = null
	effect_stack = null
	if clear_state:
		state.clear()


# 効果適用
func apply() -> void:
	pass


# 発動要求受付
func queue_activation(data: EnemyEffectActivationData) -> void:
	if effect_stack != null:
		effect_stack.request(self, data)


# 状態整数取得
func get_state_int(key: String, default_value := 0) -> int:
	return int(state.get_value(key, default_value))


# 状態値設定
func set_state(key: String, value: Variant) -> void:
	state.set_value(key, value)


# 参照値取得
func resolve_value(source_type: ValueSource, fixed_value := 0) -> int:
	return resolve_value_from(source_type, fixed_value, _activation_data)


# 指定参照値取得
func resolve_value_from(
	source_type: ValueSource,
	fixed_value: int,
	data: EnemyEffectActivationData
) -> int:
	match source_type:
		ValueSource.SELF_CURRENT_HP: return owner.hp.current if owner != null else 0
		ValueSource.SELF_MAX_HP: return owner.hp.maximum if owner != null else 0
		ValueSource.SELF_ATTACK: return owner.attack.get_modified_value(owner.attack.get_value()) if owner != null else 0
		ValueSource.DIGESTED_MINUTES: return owner.stomach_status.elapsed_minutes if owner != null else 0
		ValueSource.LOST_HP: return maxi(0, owner.hp.maximum - owner.hp.current) if owner != null else 0
		ValueSource.FIXED: return fixed_value
	return get_event_value(source_type, data)


# 発動固有値取得
func get_event_value(_source_type: ValueSource, _data: EnemyEffectActivationData) -> int:
	return 0
