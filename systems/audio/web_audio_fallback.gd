class_name WebAudioFallbackService
extends Node

const BGM_MIME_TYPE := "audio/mpeg"

var _enabled := false
var _bgm_audio: Variant
var _bgm_stream_key := ""
var _se_audio_by_channel: Dictionary = {}
var _data_uri_by_stream: Dictionary = {}
var _master_volume := 1.0
var _bgm_volume := 1.0
var _se_volume := 1.0
var _play_resolved_callback: Variant
var _play_rejected_callback: Variant


func _ready() -> void:
	_enabled = OS.has_feature("web")
	if not _enabled:
		return
	_play_resolved_callback = JavaScriptBridge.create_callback(_on_play_resolved)
	_play_rejected_callback = JavaScriptBridge.create_callback(_on_play_rejected)
	var game_settings := get_node_or_null("/root/GameSettings")
	if game_settings == null:
		push_error("WebAudioFallback requires the GameSettings autoload.")
		return
	if not game_settings.settings_changed.is_connected(_on_settings_changed):
		game_settings.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()


func is_enabled() -> bool:
	return _enabled


func play_bgm(stream: AudioStream, from_position: float = 0.0) -> bool:
	if not _enabled:
		return false
	var stream_key := _get_stream_key(stream)
	if stream_key.is_empty():
		return true
	if _bgm_audio == null or _bgm_stream_key != stream_key:
		_stop_audio(_bgm_audio)
		_bgm_audio = _create_audio(stream, true, _get_effective_bgm_volume())
		_bgm_stream_key = stream_key if _bgm_audio != null else ""
	if _bgm_audio == null:
		return true
	_bgm_audio.currentTime = maxf(from_position, 0.0)
	_play_audio(_bgm_audio)
	return true


func stop_bgm() -> bool:
	if not _enabled:
		return false
	_stop_audio(_bgm_audio)
	return true


func pause_bgm() -> bool:
	if not _enabled:
		return false
	if _bgm_audio != null:
		_bgm_audio.pause()
	return true


func resume_bgm() -> bool:
	if not _enabled:
		return false
	if _bgm_audio != null:
		_play_audio(_bgm_audio)
	return true


func is_bgm_playing() -> bool:
	if not _enabled or _bgm_audio == null:
		return false
	return not bool(_bgm_audio.paused) and not bool(_bgm_audio.ended)


func get_bgm_position() -> float:
	if not _enabled or _bgm_audio == null:
		return 0.0
	return float(_bgm_audio.currentTime)


func play_se(stream: AudioStream, channel: StringName) -> bool:
	if not _enabled:
		return false
	var stream_key := _get_stream_key(stream)
	if stream_key.is_empty():
		return true
	var channel_key := String(channel)
	var entry: Dictionary = _se_audio_by_channel.get(channel_key, {})
	var audio: Variant = entry.get("audio")
	if audio == null or String(entry.get("stream_key", "")) != stream_key:
		_stop_audio(audio)
		audio = _create_audio(stream, false, _get_effective_se_volume())
		entry = {
			"audio": audio,
			"stream_key": stream_key,
		}
		_se_audio_by_channel[channel_key] = entry
	if audio == null:
		return true
	audio.pause()
	audio.currentTime = 0.0
	_play_audio(audio)
	return true


func stop_se(channel: StringName) -> bool:
	if not _enabled:
		return false
	var entry: Dictionary = _se_audio_by_channel.get(String(channel), {})
	_stop_audio(entry.get("audio"))
	return true


func _create_audio(stream: AudioStream, loop: bool, volume: float) -> Variant:
	var data_uri := _get_data_uri(stream)
	if data_uri.is_empty():
		return null
	var audio: Variant = JavaScriptBridge.create_object("Audio")
	if audio == null:
		push_error("WebAudioFallback could not create an HTMLAudioElement.")
		return null
	audio.preload = "auto"
	audio.loop = loop
	audio.volume = volume
	audio.src = data_uri
	return audio


func _get_data_uri(stream: AudioStream) -> String:
	if not stream is AudioStreamMP3:
		push_error("WebAudioFallback supports AudioStreamMP3 resources only.")
		return ""
	var stream_key := _get_stream_key(stream)
	if _data_uri_by_stream.has(stream_key):
		return String(_data_uri_by_stream[stream_key])
	var mp3_stream := stream as AudioStreamMP3
	if mp3_stream.data.is_empty():
		push_error("WebAudioFallback received an empty MP3 resource: %s" % stream_key)
		return ""
	var data_uri := "data:%s;base64,%s" % [BGM_MIME_TYPE, Marshalls.raw_to_base64(mp3_stream.data)]
	_data_uri_by_stream[stream_key] = data_uri
	return data_uri


func _get_stream_key(stream: AudioStream) -> String:
	if stream == null:
		push_error("WebAudioFallback requires an audio stream.")
		return ""
	if not stream.resource_path.is_empty():
		return stream.resource_path
	return str(stream.get_instance_id())


func _play_audio(audio: Variant) -> void:
	if audio == null:
		return
	var promise: Variant = audio.play()
	if promise != null:
		promise.then(_play_resolved_callback, _play_rejected_callback)


func _stop_audio(audio: Variant) -> void:
	if audio == null:
		return
	audio.pause()
	audio.currentTime = 0.0


func _on_settings_changed() -> void:
	var game_settings := get_node_or_null("/root/GameSettings")
	if game_settings == null:
		return
	_master_volume = clampf(float(game_settings.master_volume) / 100.0, 0.0, 1.0)
	_bgm_volume = clampf(float(game_settings.bgm_volume) / 100.0, 0.0, 1.0)
	_se_volume = clampf(float(game_settings.se_volume) / 100.0, 0.0, 1.0)
	if _bgm_audio != null:
		_bgm_audio.volume = _get_effective_bgm_volume()
	for entry_value in _se_audio_by_channel.values():
		var entry := entry_value as Dictionary
		var audio: Variant = entry.get("audio")
		if audio != null:
			audio.volume = _get_effective_se_volume()


func _get_effective_bgm_volume() -> float:
	return _master_volume * _bgm_volume


func _get_effective_se_volume() -> float:
	return _master_volume * _se_volume


func _on_play_resolved(_arguments: Array) -> void:
	pass


func _on_play_rejected(arguments: Array) -> void:
	if arguments.is_empty():
		push_warning("Browser audio playback was rejected for an unknown reason.")
		return
	var error: Variant = arguments[0]
	var error_name := str(error.name)
	if error_name == "AbortError":
		return
	push_warning("Browser audio playback was rejected (%s): %s" % [error_name, str(error.message)])
