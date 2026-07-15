class_name EnemyNodeEffect
extends EnemyEffect

var source: Enemy # Scene依存所有者
var _trigger_connections: Array[Dictionary] = [] # Signal接続一覧


# Scene所有者設定
func bind_source(owner_node: Enemy) -> void:
	source = owner_node


# Trigger接続
func connect_trigger(source_signal: Signal, callback: Callable) -> void:
	if not source_signal.is_connected(callback):
		source_signal.connect(callback)
	_trigger_connections.append({"signal": source_signal, "callback": callback})


# Trigger解除
func unbind_triggers() -> void:
	for connection in _trigger_connections:
		var source_signal: Signal = connection["signal"]
		var callback: Callable = connection["callback"]
		if source_signal.is_connected(callback):
			source_signal.disconnect(callback)
	_trigger_connections.clear()


# 要求可能判定
func can_request(data: EnemyEffectActivationData) -> bool:
	return source != null and is_instance_valid(source) and super.can_request(data)


# 接続解除
func unbind(clear_state := true) -> void:
	super.unbind(clear_state)
	source = null
