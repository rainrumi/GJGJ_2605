class_name EnemyEffectStack
extends RefCounted

const MAX_REQUESTS_PER_CHAIN := 1000

var _pending: Array[EnemyEffectRequest] = [] # 待機要求
var _next_batch: Array[EnemyEffectRequest] = [] # 次回要求
var _is_processing := false # 実行中
var _is_scheduled := false # 実行予約済み
var _next_sequence := 0 # 次受付順


# スタック初期化
func clear() -> void:
	_pending.clear()
	_next_batch.clear()
	_is_processing = false
	_is_scheduled = false
	_next_sequence = 0


# 発動要求追加
func request(effect: EnemyEffect, activation_data: EnemyEffectActivationData = null) -> bool:
	if effect == null or not effect.can_request(activation_data):
		return false
	var request := _create_request(effect, activation_data) # 発動要求
	if _is_processing:
		_next_batch.append(request)
	else:
		_pending.append(request)
	if not _is_processing and not _is_scheduled:
		_is_scheduled = true
		call_deferred("_process_requests")
	return true


# 効果順次実行
func execute() -> void:
	_process_requests()


# 要求一括実行
func _process_requests() -> void:
	if _is_processing:
		return
	_is_scheduled = false
	_is_processing = true
	var executed_count := 0 # 連鎖実行数
	while not _pending.is_empty():
		_pending.sort_custom(_comes_before)
		var current: Array[EnemyEffectRequest] = _pending.duplicate() # 今回要求
		_pending.clear()
		for request_value in current:
			if executed_count >= MAX_REQUESTS_PER_CHAIN:
				_report_chain_limit(request_value)
				_pending.clear()
				_next_batch.clear()
				_is_processing = false
				return
			request_value.execute()
			executed_count += 1
		if not _next_batch.is_empty():
			_pending.assign(_next_batch)
			_next_batch.clear()
	_is_processing = false


# 要求作成
func _create_request(effect: EnemyEffect, activation_data: EnemyEffectActivationData) -> EnemyEffectRequest:
	var request_value := EnemyEffectRequest.new() # 新規要求
	request_value.setup(effect, activation_data, effect.priority, _next_sequence)
	_next_sequence += 1
	return request_value


# 優先順判定
func _comes_before(a: EnemyEffectRequest, b: EnemyEffectRequest) -> bool:
	if a.priority == b.priority:
		return a.sequence < b.sequence
	return a.priority < b.priority


# 連鎖上限通知
func _report_chain_limit(request_value: EnemyEffectRequest) -> void:
	var effect_name := "<null>" # 効果名
	var owner_name := "<unknown>" # 所有者名
	if request_value != null and request_value.effect != null:
		effect_name = request_value.effect.get_script().resource_path
		if request_value.effect.source != null:
			owner_name = request_value.effect.source.name
	push_error("EnemyEffectの連鎖上限を超過: effect=%s owner=%s sequence=%d" % [effect_name, owner_name, request_value.sequence if request_value != null else -1])
