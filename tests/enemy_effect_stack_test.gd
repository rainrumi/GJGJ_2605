extends SceneTree

var _failures := 0 # 失敗数


class TestActivationData:
	extends EnemyEffectActivationData

	var value := 0 # 試験値


	# 試験値初期化
	func _init(next_value: int) -> void:
		value = next_value


class TestEffect:
	extends EnemyEffect

	var output: Array[int] # 実行記録
	var stack: EnemyEffectStack # 対象スタック
	var chained_effect: EnemyEffect # 連鎖効果


	# 試験効果初期化
	func setup(values: Array[int], target_stack: EnemyEffectStack) -> void:
		output = values
		stack = target_stack


	# 試験効果適用
	func apply() -> void:
		var data := get_activation_data() as TestActivationData # 試験発動値
		if data == null:
			return
		output.append(data.value)
		if data.value == 1 and chained_effect != null:
			stack.request(chained_effect, TestActivationData.new(4))


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# スタック試験
func _run() -> void:
	var output: Array[int] = [] # 実行記録
	var stack := EnemyEffectStack.new() # 対象スタック
	var slow := TestEffect.new() # 後順位効果
	var fast := TestEffect.new() # 先順位効果
	var slow_owner := Enemy.new() # 後順位所有者
	var fast_owner := Enemy.new() # 先順位所有者
	slow.source = slow_owner
	fast.source = fast_owner
	slow.priority = 10
	fast.priority = 0
	slow.setup(output, stack)
	fast.setup(output, stack)
	slow.chained_effect = fast
	_expect(stack.request(slow, TestActivationData.new(1)), "1件目を受理する")
	_expect(stack.request(slow, TestActivationData.new(2)), "同一Effectの2件目を受理する")
	_expect(stack.request(fast, TestActivationData.new(3)), "優先Effectを受理する")
	await process_frame
	_expect(output == [3, 1, 2, 4], "優先度・受付順・次バッチを維持する")
	_expect(slow.get_activation_data() == null, "実行後に発動値を破棄する")
	slow.unbind()
	fast.unbind()
	slow_owner.free()
	fast_owner.free()
	quit(_failures)


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyEffectStackTest: %s" % message)
