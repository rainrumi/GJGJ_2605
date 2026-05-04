- 以下のメモは書き方例のため読まなくて良い
```
# シーン・ノード・信号の契約

## `main.tscn` / `main.gd`

想定されるエクスポート変数・スクリプト内参照:

```gdscript
@export var mob_scene: PackedScene
@onready var score_timer: Timer = $ScoreTimer
@onready var mob_timer: Timer = $MobTimer
@onready var start_timer: Timer = $StartTimer
@onready var player: Area2D = $Player
@onready var start_position: Marker2D = $StartPosition
@onready var mob_path: Path2D = $MobPath
@onready var hud: CanvasLayer = $HUD
@onready var music: AudioStreamPlayer = $Music
@onready var death_sound: AudioStreamPlayer = $DeathSound
```

必要な子ノード:

- `ColorRect`
- `Player`
- `MobTimer`
- `ScoreTimer`
- `StartTimer`
- `StartPosition`
- `MobPath/MobSpawnLocation`
- `HUD`
- `Music`
- `DeathSound`

現在の信号接続:

- `Player.hit -> Main.game_over`
- `MobTimer.timeout -> Main._on_mob_timer_timeout`
- `ScoreTimer.timeout -> Main._on_score_timer_timeout`
- `StartTimer.timeout -> Main._on_start_timer_timeout`
- `HUD.start_game -> Main.new_game`

## `player.tscn` / `player.gd`

ルート型: `Area2D`。

必要な子ノード:

- `AnimatedSprite2D`
- `CollisionShape2D`

現在の信号接続:

- `Player.body_entered -> Player._on_body_entered`

契約:

- ボディと衝突したら `hit` を発行する。
- `start(pos: Vector2)` はプレイヤーを表示し、位置を設定し、コリジョンを再有効化する。
- 移動範囲は現在のビューポートサイズ内に制限する。
- 現在使われているアニメーション名は `walk` と `up`。

## `mob.tscn` / `mob.gd`

ルート型: `RigidBody2D`。

必要な子ノード:

- `AnimatedSprite2D`
- `CollisionShape2D`
- `VisibleOnScreenNotifier2D`

現在の信号接続:

- `VisibleOnScreenNotifier2D.screen_exited -> Mob._on_visible_on_screen_notifier_2d_screen_exited`

契約:

- `gravity_scale = 0.0` により重力を無効化している。
- コリジョンマスクは現在 `0`。
- 既存の `SpriteFrames` にあるアニメーション名からランダムに選ぶ。
- Mobは画面外へ出たあと、自身を解放する。

既知の注意点:

- `main.gd` は `get_tree().call_group("mobs", "queue_free")` を呼ぶが、現在の `mob.tscn` には `mobs` グループ定義が見当たらない。再スタート時の掃除挙動を修正する場合は、`mob.tscn` 側で `mobs` グループに入れるか、インスタンス化後に `mob.add_to_group("mobs")` を呼ぶこと。意図された再スタート挙動を理解しないまま、掃除呼び出しを削除しない。

## `hud.tscn` / `hud.gd`

ルート型: `CanvasLayer`。

必要な子ノード:

- `ScoreLabel`
- `Message`
- `MessageTimer`
- `StartButton`

現在の信号接続:

- `StartButton.pressed -> HUD._on_start_button_pressed`
- `MessageTimer.timeout -> HUD._on_message_timer_timeout`

契約:

- スタートボタンが押されたら `start_game` を発行する。
- `show_message(text)` はメッセージを表示し、`MessageTimer` を開始する。
- `show_game_over()` は `Game Over` を表示し、メッセージタイマーを待ち、タイトルテキストを戻し、1秒後にスタートボタンを表示する。
- `update_score(score)` はスコアをプレーンテキストとして表示する。
```
