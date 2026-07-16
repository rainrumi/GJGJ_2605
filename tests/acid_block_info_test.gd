extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var block := AcidBlockInfo.new()
	block.stomach_shape = [
		PackedInt32Array([1, 0, 0]),
		PackedInt32Array([1, 1, 1]),
	]
	_expect(block.get_stomach_size() == Vector2i(3, 2), "StomachSizeが形状の幅と高さに一致")

	block.stomach_shape = [
		PackedInt32Array([1]),
		PackedInt32Array([1, 1, 1, 1]),
	]
	_expect(block.get_stomach_size() == Vector2i(4, 2), "StomachSizeが最長行の幅を使用")

	var empty_shape: Array[PackedInt32Array] = []
	block.stomach_shape = empty_shape
	_expect(block.get_stomach_size() == Vector2i.ONE, "空のStomachShapeは1x1")
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("AcidBlockInfoTest: %s" % message)
