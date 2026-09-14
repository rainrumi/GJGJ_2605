extends SceneTree

const MODEL_FILES := [
	"res://scene/main/game/enemy/model/enemy_hp.gd",
	"res://scene/main/game/enemy/model/battle_clock.gd",
	"res://scene/main/game/enemy/model/enemy_stomach_status.gd",
	"res://scene/main/game/enemy/model/enemy_digestion_state.gd",
]
const FORBIDDEN_NAMES := [
	"EnemyEffect",
	"ActivationData",
	"EnemyEffectStack",
	"EnemyEffectSystem",
	"EnemyEffectInstaller",
]

var _failures := 0 # 失敗数


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# Model依存試験
func _run() -> void:
	for path in MODEL_FILES:
		var source := FileAccess.get_file_as_string(path) # Modelソース
		for forbidden in FORBIDDEN_NAMES:
			_expect(not source.contains(forbidden), "%s が %s に依存しない" % [path, forbidden])
	var hp := EnemyHp.new() # HP状態
	var damaged_values: Array[int] = [] # 被弾通知値
	hp.setup(10)
	hp.damaged.connect(func(amount: int) -> void: damaged_values.append(amount))
	hp.take_damage(4)
	_expect(damaged_values == [4], "HP変更は普遍的な被弾量だけを通知する")
	_expect(hp.lost_hp_total == 4, "実際に減ったHPを累計する")
	hp.heal(2)
	_expect(hp.lost_hp_total == 4, "回復では失HP累計を減らさない")
	hp.set_current(5)
	hp.set_values(12, 4)
	_expect(hp.lost_hp_total == 8, "現在HPを直接減らす経路も累計する")
	hp.take_damage(20)
	_expect(hp.lost_hp_total == 12, "過剰ダメージは実際に減ったHPまで数える")
	hp.setup(10)
	_expect(hp.lost_hp_total == 0, "HP初期化時に失HP累計をリセットする")
	hp.take_damage(2)
	hp.reset_lost_hp()
	_expect(hp.lost_hp_total == 0, "戦闘リセット時に失HP累計をリセットする")
	var clock := BattleClock.new() # 時刻状態
	var progressed_values: Array[int] = [] # 時刻通知値
	clock.progressed.connect(func(elapsed: int, current: int) -> void:
		progressed_values.assign([elapsed, current])
	)
	clock.set_time(30, 120)
	_expect(progressed_values == [30, 120], "時刻変更は普遍的な秒数だけを通知する")
	quit(_failures)


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyModelDependencyTest: %s" % message)
