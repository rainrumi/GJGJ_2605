# Godot BGM拍同期システム実装仕様書 for Codex

## 目的

Godot 4.x プロジェクトに、BGMの拍にゲーム内イベントを同期させる共通システムを実装する。

主な用途は、敵へのダメージ、演出、UI反応、SE再生などを「次の拍」「次の細分拍」「指定された曲時間」に合わせて実行すること。

この仕様書は、特定シーン専用ではなく、今後の他シーンにも再利用できる共通設計として実装すること。

---

## 実装方針

### 必須方針

- BGM同期用の責務は、専用ノード `BeatConductor` に集約する。
- 各ゲームシーンは `AudioStreamPlayer` を直接参照して拍計算しない。
- ゲームイベントは即時実行せず、必要に応じて `BeatConductor` に予約する。
- 拍同期はゲーム時間や `Timer` ではなく、音声再生位置を基準にする。
- 実装は Godot 4.x GDScript を前提とする。
- 既存シーンの責務集中を増やさない。
- 既存のゲームロジックに音声同期計算を直接混ぜ込まない。

---

## Godotで使う同期方式

Godotでは、`AudioStreamPlayer.get_playback_position()` は音声ミックスのチャンク単位で更新されるため、そのままでは精度が不足しやすい。

より正確な曲時間は、以下の補正式を使う。

```gdscript
audio_time = player.get_playback_position()
audio_time += AudioServer.get_time_since_last_mix()
audio_time -= AudioServer.get_output_latency()
```

この補正式を `BeatConductor` 内に閉じ込め、他のスクリプトが直接この計算を持たないようにする。

注意：
`AudioServer.get_output_latency()` は毎フレーム呼ばず、必要に応じてキャッシュしてよい。

---

## 追加する共通ノード構成

以下のような共通シーン、または共通ノードを作成する。

```text
BeatConductor
└── AudioStreamPlayer
```

推奨ファイル：

```text
res://systems/audio/beat_conductor.tscn
res://systems/audio/beat_conductor.gd
```

既存プロジェクトのディレクトリ規則がある場合は、それに合わせること。

---

## BeatConductor の責務

`BeatConductor` は以下のみを担当する。

- BGMの再生
- 正確寄りの曲時間取得
- BPMから拍間隔を計算
- 拍・細分拍の検出
- 次の拍時刻を返す
- 次の細分拍時刻を返す
- 指定曲時間へのイベント予約
- 予約イベントの実行
- 必要なら予約イベントのキャンセル
- signalによる拍通知

以下は担当しない。

- 敵のHP処理
- UIの具体的な更新
- ダメージ計算
- ステージ進行
- 入力処理
- 各シーン固有のノード操作

---

## BeatConductor の公開API

以下の public method を実装すること。

```gdscript
func play(from_position: float = 0.0) -> void
func stop() -> void
func pause() -> void
func resume() -> void

func get_song_time() -> float
func get_beat_interval() -> float
func get_subdivision_interval() -> float

func get_current_beat_index() -> int
func get_current_subdivision_index() -> int

func get_next_beat_time() -> float
func get_next_subdivision_time() -> float
func get_next_grid_time(subdivision_count: int) -> float

func schedule_at_song_time(song_time: float, callback: Callable) -> int
func schedule_on_next_beat(callback: Callable) -> int
func schedule_on_next_subdivision(callback: Callable) -> int
func schedule_on_next_grid(subdivision_count: int, callback: Callable) -> int

func cancel_event(event_id: int) -> void
func clear_scheduled_events() -> void
```

---

## BeatConductor の export 変数

Inspectorから調整できるようにすること。

```gdscript
@export var bpm: float = 120.0
@export var beat_offset: float = 0.0
@export var subdivisions: int = 4
@export var auto_play: bool = true
@export var use_output_latency_compensation: bool = true
@export var bgm_stream: AudioStream
@export var debug_print_beats: bool = false
```

| 変数 | 意味 |
|---|---|
| `bpm` | 曲のBPM |
| `beat_offset` | 曲頭の無音や拍ズレ補正。秒単位 |
| `subdivisions` | 1拍を何分割するか。4なら16分相当 |
| `auto_play` | `_ready()` で自動再生するか |
| `use_output_latency_compensation` | 出力レイテンシ補正を使うか |
| `bgm_stream` | 再生するBGM |
| `debug_print_beats` | 拍ログを出すか |

---

## BeatConductor の signal

以下の signal を実装すること。

```gdscript
signal beat(beat_index: int, song_time: float)
signal subdivision(subdivision_index: int, song_time: float)
signal scheduled_event_executed(event_id: int, song_time: float)
signal playback_started()
signal playback_stopped()
```

### signalの用途

- `beat`：4分拍など、BPMの基本拍で演出したい場合
- `subdivision`：8分、16分など細かいタイミングで処理したい場合
- `scheduled_event_executed`：デバッグ、ログ、テスト用
- `playback_started` / `playback_stopped`：UIや遷移管理用

---

## BeatConductor 実装例

Codexは以下の構造を基準に実装すること。既存コードに合わせる場合でも、責務とAPIは維持すること。

```gdscript
class_name BeatConductor
extends Node

signal beat(beat_index: int, song_time: float)
signal subdivision(subdivision_index: int, song_time: float)
signal scheduled_event_executed(event_id: int, song_time: float)
signal playback_started()
signal playback_stopped()

@export var bpm: float = 120.0
@export var beat_offset: float = 0.0
@export var subdivisions: int = 4
@export var auto_play: bool = true
@export var use_output_latency_compensation: bool = true
@export var bgm_stream: AudioStream
@export var debug_print_beats: bool = false

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var _beat_interval: float = 0.0
var _subdivision_interval: float = 0.0
var _last_beat_index: int = -1
var _last_subdivision_index: int = -1
var _event_id_counter: int = 0
var _scheduled_events: Array[Dictionary] = []
var _cached_output_latency: float = 0.0

func _ready() -> void:
    _recalculate_intervals()

    if audio_player == null:
        push_error("BeatConductor requires an AudioStreamPlayer child.")
        return

    if bgm_stream != null:
        audio_player.stream = bgm_stream

    _cached_output_latency = AudioServer.get_output_latency()

    if auto_play and audio_player.stream != null:
        play()

func _process(_delta: float) -> void:
    if audio_player == null:
        return

    if not audio_player.playing:
        return

    var song_time := get_song_time()
    if song_time < 0.0:
        return

    _emit_rhythm_signals(song_time)
    _process_scheduled_events(song_time)

func play(from_position: float = 0.0) -> void:
    if audio_player == null:
        return

    _last_beat_index = -1
    _last_subdivision_index = -1
    audio_player.play(from_position)
    playback_started.emit()

func stop() -> void:
    if audio_player == null:
        return

    audio_player.stop()
    clear_scheduled_events()
    _last_beat_index = -1
    _last_subdivision_index = -1
    playback_stopped.emit()

func pause() -> void:
    if audio_player == null:
        return

    audio_player.stream_paused = true

func resume() -> void:
    if audio_player == null:
        return

    audio_player.stream_paused = false

func get_song_time() -> float:
    if audio_player == null:
        return 0.0

    var time := audio_player.get_playback_position()
    time += AudioServer.get_time_since_last_mix()

    if use_output_latency_compensation:
        time -= _cached_output_latency

    time -= beat_offset
    return time

func get_beat_interval() -> float:
    return _beat_interval

func get_subdivision_interval() -> float:
    return _subdivision_interval

func get_current_beat_index() -> int:
    var song_time := get_song_time()
    if song_time < 0.0:
        return -1
    return int(floor(song_time / _beat_interval))

func get_current_subdivision_index() -> int:
    var song_time := get_song_time()
    if song_time < 0.0:
        return -1
    return int(floor(song_time / _subdivision_interval))

func get_next_beat_time() -> float:
    var song_time := max(get_song_time(), 0.0)
    return ceil(song_time / _beat_interval) * _beat_interval

func get_next_subdivision_time() -> float:
    var song_time := max(get_song_time(), 0.0)
    return ceil(song_time / _subdivision_interval) * _subdivision_interval

func get_next_grid_time(subdivision_count: int) -> float:
    var safe_subdivision_count := max(subdivision_count, 1)
    var interval := _beat_interval / float(safe_subdivision_count)
    var song_time := max(get_song_time(), 0.0)
    return ceil(song_time / interval) * interval

func schedule_at_song_time(song_time: float, callback: Callable) -> int:
    _event_id_counter += 1

    _scheduled_events.append({
        "id": _event_id_counter,
        "time": song_time,
        "callback": callback,
        "cancelled": false,
    })

    _scheduled_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return float(a["time"]) < float(b["time"])
    )

    return _event_id_counter

func schedule_on_next_beat(callback: Callable) -> int:
    return schedule_at_song_time(get_next_beat_time(), callback)

func schedule_on_next_subdivision(callback: Callable) -> int:
    return schedule_at_song_time(get_next_subdivision_time(), callback)

func schedule_on_next_grid(subdivision_count: int, callback: Callable) -> int:
    return schedule_at_song_time(get_next_grid_time(subdivision_count), callback)

func cancel_event(event_id: int) -> void:
    for event in _scheduled_events:
        if int(event["id"]) == event_id:
            event["cancelled"] = true
            return

func clear_scheduled_events() -> void:
    _scheduled_events.clear()

func _recalculate_intervals() -> void:
    var safe_bpm := max(bpm, 1.0)
    var safe_subdivisions := max(subdivisions, 1)

    _beat_interval = 60.0 / safe_bpm
    _subdivision_interval = _beat_interval / float(safe_subdivisions)

func _emit_rhythm_signals(song_time: float) -> void:
    var beat_index := int(floor(song_time / _beat_interval))
    if beat_index != _last_beat_index:
        _last_beat_index = beat_index
        beat.emit(beat_index, song_time)

        if debug_print_beats:
            print("beat:", beat_index, " song_time:", song_time)

    var subdivision_index := int(floor(song_time / _subdivision_interval))
    if subdivision_index != _last_subdivision_index:
        _last_subdivision_index = subdivision_index
        subdivision.emit(subdivision_index, song_time)

func _process_scheduled_events(song_time: float) -> void:
    var executed_ids: Array[int] = []

    for event in _scheduled_events:
        var event_time := float(event["time"])
        if event_time > song_time:
            break

        executed_ids.append(int(event["id"]))

        if not bool(event["cancelled"]):
            var callback: Callable = event["callback"]
            if callback.is_valid():
                callback.call()

            scheduled_event_executed.emit(int(event["id"]), song_time)

    if executed_ids.is_empty():
        return

    _scheduled_events = _scheduled_events.filter(func(event: Dictionary) -> bool:
        return not executed_ids.has(int(event["id"]))
    )
```

---

## 既存コードへの接続方針

### 悪い実装

各シーンで直接以下を行わないこと。

```gdscript
var t = bgm.get_playback_position()
var next = ceil(t / beat_interval) * beat_interval
await get_tree().create_timer(next - t).timeout
target.take_damage(amount)
```

理由：

- 音声同期計算が分散する
- 出力遅延補正が漏れる
- シーンごとに挙動がズレる
- リファクタリング不能になる

### 良い実装

各シーンは以下のように `BeatConductor` に予約する。

```gdscript
func request_damage(target: Node, amount: int) -> void:
    beat_conductor.schedule_on_next_beat(
        func() -> void:
            if is_instance_valid(target):
                target.take_damage(amount)
    )
```

または16分単位に合わせる。

```gdscript
func request_damage_on_subdivision(target: Node, amount: int) -> void:
    beat_conductor.schedule_on_next_subdivision(
        func() -> void:
            if is_instance_valid(target):
                target.take_damage(amount)
    )
```

---

## ダメージ同期の推奨設計

### 基本ルール

- 入力・選択・予告表示は即時実行してよい。
- 実ダメージ、HP減少、SE、ヒットエフェクトは拍に予約して実行する。
- 予約前に対象が有効か確認する。
- 実行時にも `is_instance_valid()` で対象が存在するか確認する。
- 拍同期が必要な処理と即時処理を混ぜない。

### 推奨フロー

```text
プレイヤー操作
↓
対象選択・予告表示
↓
ダメージイベントをBeatConductorへ予約
↓
次の拍または細分拍に到達
↓
対象がまだ存在するか確認
↓
ダメージ処理
↓
ヒット演出 / SE / UI更新
```

---

## 予約キャンセルの仕様

対象が消えた、シーン遷移した、戦闘が終了した場合に備えて、予約IDを保持できるようにする。

```gdscript
var damage_event_id := beat_conductor.schedule_on_next_beat(
    func() -> void:
        if is_instance_valid(target):
            target.take_damage(amount)
)
```

キャンセルする場合：

```gdscript
beat_conductor.cancel_event(damage_event_id)
```

シーン終了時：

```gdscript
beat_conductor.clear_scheduled_events()
```

---

## ループBGMへの対応

初期実装では、以下のどちらかを選ぶこと。

### 最低要件

- ループBGMで予約イベントが壊れないよう、曲終了・停止時に予約をクリアする。
- ループポイントを厳密に扱わない場合、その制限をコメントに明記する。

### 拡張対応

以下の export を追加してもよい。

```gdscript
@export var loop_start_time: float = 0.0
@export var loop_length: float = 0.0
```

ただし、初期実装では複雑化しすぎないこと。必要なら別タスクに分離する。

---

## BPM変化への対応

初期実装は固定BPMでよい。

ただし、将来の拡張を考えて、以下の設計を壊さないこと。

```text
BeatConductor
└── BPM Map / Chart Data
```

テンポ変化が必要になった場合は、BPM計算ではなく、事前に定義した拍時刻配列を使う。

---

## 譜面データ方式の拡張仕様

固定BPMで不足する場合、以下のような Resource を追加する。

```gdscript
class_name BeatChart
extends Resource

@export var beat_times: Array[float] = []
@export var subdivision_times: Array[float] = []
```

`BeatConductor` は `BeatChart` が設定されている場合、BPM計算より `beat_times` を優先してもよい。

ただし、今回の初期実装では必須ではない。

---

## シーン構造ルール

### 各シーンに置いてよいもの

- `BeatConductor` への参照
- `BeatConductor` の signal 接続
- 拍同期したいイベントの予約呼び出し

### 各シーンに置いてはいけないもの

- BPMから拍時刻を計算する重複コード
- `AudioServer.get_time_since_last_mix()` の直接呼び出し
- `AudioServer.get_output_latency()` の直接呼び出し
- `AudioStreamPlayer.get_playback_position()` を使った独自同期処理
- `Timer` による疑似拍同期処理
- BGM同期とゲームロジックが混ざった巨大関数

---

## Godot的な責務分離ルール

- `BeatConductor` は音楽時間を管理する。
- ダメージ処理は対象オブジェクト側に置く。
- 戦闘ルールは戦闘管理側に置く。
- UI表示はUI側に置く。
- `BeatConductor` は「いつ実行するか」だけを決める。
- `BeatConductor` は「何を実行するか」の中身を知らない。

つまり、以下を守る。

```text
いつ実行するか = BeatConductor
何を実行するか = 呼び出し元がCallableで渡す
具体的な効果 = 各責務のスクリプトが持つ
```

---

## テスト観点

Codexは実装後、以下を確認すること。

### 必須確認

- BGMが再生される。
- `get_song_time()` が再生中に増加する。
- `beat` signal がBPMに応じて発火する。
- `subdivision` signal が `subdivisions` に応じて発火する。
- `schedule_on_next_beat()` に渡した処理が次の拍で実行される。
- `schedule_on_next_subdivision()` に渡した処理が次の細分拍で実行される。
- `cancel_event()` した処理は実行されない。
- `clear_scheduled_events()` 後に予約処理が実行されない。
- 対象ノードが消えていてもクラッシュしない。

### 体感確認

- ダメージ演出がBGM拍におおむね一致する。
- `beat_offset` を変えると体感タイミングが調整できる。
- FPSが多少揺れても、拍タイミングが大きく崩れない。

---

## 禁止事項

以下の実装は禁止。

- 各ゲームシーンにBPM計算を直接書く。
- `await create_timer()` を使って拍同期の本体を実装する。
- ダメージ処理の中にBGM同期処理を直接書く。
- UIスクリプトがAudioServerを直接参照する。
- `BeatConductor` が敵やUIなどシーン固有ノードを直接参照する。
- `BeatConductor` にシーン固有の処理名を持ち込む。
- 予約キューに無効ノードを前提とした危険な処理を書く。
- signalとCallableの責務を混ぜ、依存方向を曖昧にする。

---

## 期待する最終状態

実装後は、ゲーム内の任意の処理を以下の形で拍に同期できること。

```gdscript
beat_conductor.schedule_on_next_beat(
    func() -> void:
        if is_instance_valid(target):
            target.take_damage(amount)
)
```

または：

```gdscript
beat_conductor.schedule_on_next_grid(
    4,
    func() -> void:
        if is_instance_valid(target):
            target.play_hit_effect()
)
```

この形にすることで、各ゲームシーンは音声同期の詳細を知らずに済み、責務が集中しにくくなる。

---

## Codexへの実装優先度

### A: 必須

- `BeatConductor` の作成
- 正確寄りの曲時間取得
- BPM / subdivisions 対応
- beat / subdivision signal
- 予約イベントキュー
- キャンセル機能
- 既存処理からの利用例を1箇所作る

### B: 推奨

- `beat_offset` のInspector調整
- output latency のキャッシュ
- デバッグログ切り替え
- シーン終了時の予約クリア
- 対象ノード無効化への安全対応

### C: 後回し

- ループポイント厳密対応
- BPM変化対応
- BeatChart Resource
- エディタ用ビート可視化
- 入力判定窓の実装

---

## 実装時のコメント方針

コード内コメントは、日本語で簡潔に書くこと。

例：

```gdscript
# AudioStreamPlayerの再生位置だけではチャンク単位で粗いため、AudioServerの補正値を加える。
```

冗長な説明や、仕様書と同じ長文コメントは書かないこと。
