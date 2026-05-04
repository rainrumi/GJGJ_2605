# プロジェクト概要

## エンジンとプロジェクト形状

- Godot設定バージョン: `config_version=5`。
- 宣言されている機能タグ: `4.6`。
- メインシーン: `main.tscn`。
- ウィンドウビューポート: `1280 x 720`。
- ストレッチモード: `canvas_items`。
- レンダリング設定にはWindows D3D12が含まれる。
- 物理設定では3D向けにJoltが指定されているが、実際のゲームは2Dである。
- Webエクスポートプリセットがあり、`../Build/index.html` へ出力する。

## 現在のフォルダ構成

```text
project root/
  project.godot
  export_presets.cfg
  main.gd / main.tscn
  player.gd / player.tscn
  mob.gd / mob.tscn
  hud.gd / hud.tscn
  art/
  fonts/
```

生成物・エディタ専用の内容:

```text
.godot/
*.import
*.gd.uid
```

指示がない限り、プロジェクト構成を整理し直さないこと。現在の構成は、意図的にフラットでチュートリアル寄りである。

## ゲームループ

- 以下のメモは書き方例のため読まなくて良い
```
- `HUD` が `start_game` を発行する。
- `Main.new_game()` がスコアをリセットし、プレイヤーを開始位置に戻し、`StartTimer` を開始し、HUDを更新し、Mobを掃除し、BGMを再生する。
- `StartTimer.timeout` により、`MobTimer` と `ScoreTimer` が開始される。
- `MobTimer.timeout` は `mob_scene` をインスタンス化し、`MobPath/MobSpawnLocation` 上に配置し、方向と速度をランダム化してから `Main` に追加する。
- `ScoreTimer.timeout` はスコアを増やし、HUDを更新する。
- `Player.hit` は `Main.game_over()` を呼ぶ。
- `game_over()` はタイマーを停止し、ゲームオーバーUIを表示し、BGMを止め、死亡音を再生する。
```

## 現在のシーン

- 以下のメモは書き方例のため読まなくて良い
```
- `main.tscn`: ルートは `Node`。ゲーム進行、タイマー、プレイヤーインスタンス、Mob出現パス、HUD、BGM、死亡音を持つ。
- `player.tscn`: ルートは `Area2D`。アニメーションとコリジョンを持ち、ボディ衝突時に `hit` を発行する。
- `mob.tscn`: ルートは `RigidBody2D`。`_ready()` でアニメーションをランダム化し、画面外に出たら自身を解放する。
- `hud.tscn`: ルートは `CanvasLayer`。スコアラベル、メッセージラベル、スタートボタン、メッセージタイマーを持つ。
```

## アセットとUIテキスト

- コードコメントは短い日本語メモが中心である。
- アート・サウンドのファイル名は不用意に変更しないこと。`.tscn` や `.import` から参照されている。
