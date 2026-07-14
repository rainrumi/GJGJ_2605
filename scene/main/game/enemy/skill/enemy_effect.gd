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
var runtime: EnemyEffectRuntime # 実行時値


# 実行時値設定
func prepare(next_runtime: EnemyEffectRuntime) -> void:
	runtime = next_runtime


# 効果適用
func apply() -> void:
	pass
