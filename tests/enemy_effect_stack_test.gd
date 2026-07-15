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


class LoopEffect:
	extends EnemyEffect

	var activation_count := 0 # 発動回数
	var stack: EnemyEffectStack # 対象スタック


	# 試験効果適用
	func apply() -> void:
		activation_count += 1
		stack.request(self, TestActivationData.new(activation_count))


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
	slow.bind_owner(slow_owner.data, stack)
	fast.bind_owner(fast_owner.data, stack)
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
	await _test_chain_limit()
	slow.unbind()
	fast.unbind()
	slow_owner.free()
	fast_owner.free()
	quit(_failures)


# 連鎖上限試験
func _test_chain_limit() -> void:
	var stack := EnemyEffectStack.new() # 対象スタック
	var effect := LoopEffect.new() # 連鎖効果
	var owner := Enemy.new() # 効果所有者
	effect.bind_owner(owner.data, stack)
	effect.stack = stack
	stack.request(effect, TestActivationData.new(0))
	await process_frame
	_expect(effect.activation_count == EnemyEffectStack.MAX_REQUESTS_PER_CHAIN, "無限連鎖を上限で停止する")
	effect.unbind()
	owner.free()


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyEffectStackTest: %s" % message)
