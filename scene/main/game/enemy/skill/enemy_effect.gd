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

enum Event {
	BATTLE_START,
	REFRESH,
	TURN_START,
	PROGRESS_TIME,
	BEFORE_ACID_DAMAGE,
	AFTER_ACID_DAMAGE,
	DIGESTED,
	ANY_DIGESTED,
	ADJACENT_ACID_DAMAGE,
	ADJACENT_DIGESTED,
}

# 適用順
@export var priority :int = 0
# 有効状態
@export var enabled :bool = true
var state := EnemyEffectState.new() # 個体効果状態
var _activation_data: EnemyEffectActivationData # 発動時値
var runtime: EnemyEffectRuntime:
	get:
		var legacy := _activation_data as EnemyEffectLegacyActivationData # 移行値
		return legacy.execution if legacy != null else null


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
	return enabled and data != null and data.is_valid()


# 接続解除
func unbind() -> void:
	_activation_data = null
	state.clear()


# 効果適用
func apply() -> void:
	pass
