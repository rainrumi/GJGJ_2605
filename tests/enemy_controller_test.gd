extends SceneTree

var _failures := 0 # 失敗数


class TestDigestionResolver:
	extends EnemyDigestionResolver

	var calls: Array[String] # 呼出記録


	# 試験初期化
	func setup_test(values: Array[String]) -> void:
		calls = values


	# 消化内訳取得
	func get_damage_breakdown(
		_enemies: Array[Enemy],
		_minutes: int,
		_base_damage: int,
		_consume_pending_bonus := false,
		_stomach: StomachBoard = null
	) -> Dictionary:
		return {"total": 1}


	# 消化処理解決
	func resolve(_input: EnemyDigestionInput) -> EnemyDigestionBatchResult:
		calls.append("digestion")
		return EnemyDigestionBatchResult.new()


class TestAttackResolver:
	extends EnemyAttackResolver

	var calls: Array[String] # 呼出記録


	# 試験初期化
	func setup_test(values: Array[String]) -> void:
		calls = values


	# 敵攻撃解決
	func resolve(_enemies: Array[Enemy], _stomach: StomachBoard, _minutes: int) -> Array[int]:
		calls.append("attack")
		return [3]


class TestTurnProcessor:
	extends EnemyTurnProcessor

	var calls: Array[String] # 呼出記録


	# 試験初期化
	func setup_test(values: Array[String]) -> void:
		calls = values


	# ターン開始処理
	func begin_turn(_enemies: Array[Enemy], _stomach: StomachBoard, _minutes: int) -> void:
		calls.append("begin")


	# ターン結果構築
	func build_result(digested_enemies: Array[Enemy]) -> BattleTurnResultData:
		calls.append("end")
		var result := BattleTurnResultData.new() # 試験結果
		result.Acided_enemies = digested_enemies
		return result


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# Controller試験
func _run() -> void:
	var calls: Array[String] = [] # 呼出記録
	var digestion := TestDigestionResolver.new() # 消化差替
	var attack := TestAttackResolver.new() # 攻撃差替
	var turns := TestTurnProcessor.new() # ターン差替
	digestion.setup_test(calls)
	attack.setup_test(calls)
	turns.setup_test(calls)
	var controller := EnemyController.new() # 調整対象
	controller.setup(digestion, attack, turns, EnemyEffectSystem.new())
	var input := EnemyTurnInput.new() # ターン入力
	var result := controller.process_turn(input) # ターン結果
	_expect(calls == ["begin", "digestion", "attack", "end"], "処理順を維持する")
	_expect(result.player_damage_values == [3], "攻撃結果を統合する")
	_expect(controller.digestion_resolver == digestion, "消化Resolverを差し替えられる")
	_expect(controller.attack_resolver == attack, "攻撃Resolverを差し替えられる")
	_expect(controller.turn_processor == turns, "TurnProcessorを差し替えられる")
	quit(_failures)


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyControllerTest: %s" % message)
