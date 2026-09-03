extends SceneTree

var _failures := 0


class TestActivationData:
	extends EnemyEffectActivationData


class TestEffect:
	extends EnemyEffect

	var activation_count := 0


	func apply() -> void:
		activation_count += 1


class OutsideStomachEffect:
	extends TestEffect


class DigestedEffect:
	extends TestEffect


	func can_activate_when_owner_digested() -> bool:
		return true


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stack := EnemyEffectStack.new()
	var owner := Enemy.new()
	var normal_effect := TestEffect.new()
	normal_effect.bind_owner(owner.data, stack)
	_expect(normal_effect.activates_in_stomach, "胃袋内発動のデフォルト値はtrue")
	_expect(not normal_effect.activates_outside_stomach, "胃袋外発動のデフォルト値はfalse")

	_expect(
		not stack.request(normal_effect, TestActivationData.new()),
		"通常効果は胃袋外では発動要求を受け付けない"
	)
	owner.set_Aciding(true)
	_expect(
		stack.request(normal_effect, TestActivationData.new()),
		"通常効果は胃袋内では発動要求を受け付ける"
	)
	owner.set_Aciding(false)
	stack.execute()
	_expect(normal_effect.activation_count == 0, "実行待ち中に胃袋外へ出た通常効果は発動しない")

	var outside_effect := OutsideStomachEffect.new()
	outside_effect.bind_owner(owner.data, stack)
	outside_effect.activates_outside_stomach = true
	_expect(
		stack.request(outside_effect, TestActivationData.new()),
		"胃袋外発動を明記した効果は胃袋外でも発動要求を受け付ける"
	)
	stack.execute()
	_expect(outside_effect.activation_count == 1, "胃袋外発動を明記した効果は胃袋外で発動する")

	var outside_only_effect := TestEffect.new()
	outside_only_effect.bind_owner(owner.data, stack)
	outside_only_effect.activates_in_stomach = false
	outside_only_effect.activates_outside_stomach = true
	owner.set_Aciding(true)
	_expect(
		not stack.request(outside_only_effect, TestActivationData.new()),
		"胃袋内発動を無効にした効果は胃袋内では発動しない"
	)
	owner.set_Aciding(false)
	_expect(
		stack.request(outside_only_effect, TestActivationData.new()),
		"胃袋外だけを有効にした効果は胃袋外で発動する"
	)
	stack.execute()
	_expect(outside_only_effect.activation_count == 1, "胃袋外専用効果を実行する")

	var digested_effect := DigestedEffect.new()
	digested_effect.bind_owner(owner.data, stack)
	owner.set_Acided(true)
	_expect(
		stack.request(digested_effect, TestActivationData.new()),
		"消化後発動を明記した既存効果は引き続き発動要求を受け付ける"
	)
	stack.execute()
	_expect(digested_effect.activation_count == 1, "消化後発動を明記した既存効果は発動する")

	normal_effect.unbind()
	outside_effect.unbind()
	outside_only_effect.unbind()
	digested_effect.unbind()
	owner.free()
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyEffectStomachActivationTest: %s" % message)
