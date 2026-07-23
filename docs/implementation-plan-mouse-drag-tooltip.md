# マウスドラッグ中のツールチップ抑制 Godot 実装計画

## 目的

- プレイヤーのマウス操作がドラッグ中か待機中かを一元的に判定できるようにする。
- 敵または夢の種をドラッグしている間は、既存ツールチップを非表示に保つ。

## 受入条件

- [ ] 敵ドラッグと夢の種ドラッグの開始時に共通状態がドラッグ中へ遷移する。
- [ ] 対応するドラッグが終了または取り消された時に待機中へ戻る。
- [ ] 表示済みツールチップはドラッグ開始時に閉じ、ドラッグ中の表示要求では開かない。
- [ ] クリックや左ボタン押下だけではドラッグ中にならない。
- [ ] 同じ所有者からの重複通知や複数所有者の終了順によって状態が不整合にならない。

## 現状調査

### Project

- Godot version: `project.godot` のfeatureは Godot 4.6。
- Script language: GDScript。
- Main Scene: `res://scene/main/main.tscn`。
- Autoload: `GameSettings`、`DebugState`。
- Test / CI: `tests/*.gd` の独自 `SceneTree` runner。標準検証スクリプトと `.agent/godot-agent.env` は未配置。

### 関連ファイル

- Scene: `res://scene/main/game/game.tscn` と、そのUI・敵・夢の種Scene。
- Script: `game_input_controller.gd`、`seed_button.gd`、`left_tooltip.gd`、`seed_tooltip.gd`。
- Resource / Data: 変更なし。
- ProjectSettings / InputMap: `project.godot` のAutoloadへ共通ドラッグ状態を追加する。InputMap変更なし。

### 現在の責務とデータフロー

- 敵ドラッグは `GameInputController` が入力を解釈し、開始・移動・解放signalをゲームへ通知する。
- 夢の種ドラッグは各 `SeedButton` が入力を解釈し、`SeedButtonList` と `BattleUI` を経由してゲームへ通知する。
- ステータス・HP・敵ツールチップは `LeftTooltip` を継承する。夢の種ツールチップは `SeedTooltip` が所有する。
- ドラッグ開始前から表示中のツールチップを一括して閉じる共通状態・signalは存在しない。

## 確定事項

- 既存実装はマウス移動だけでなく500msの長押しでもドラッグを開始する。
- 対象となる実ドラッグ開始点は `GameInputController._start_drag()` と `SeedButton._start_drag()` の2箇所である。
- 全ての独自ツールチップ表示は `LeftTooltip` 系または `SeedTooltip` に集約できる。

## 仮定・未確定事項

- 今回の「ドラッグ」は既存ゲーム内の敵・夢の種ドラッグを指す。将来別のドラッグ操作を追加する場合も同じtrackerへ開始・終了を通知する。
- 視覚・操作確認は利用可能なGodot実行環境に依存する。自動テストでは状態遷移と表示抑制を直接確認する。

## 設計判断

- 採用案: `MouseDragTracker` NodeをAutoloadし、ドラッグ所有者ごとの開始・終了を追跡する。待機／ドラッグ中の公開照会と状態遷移signalを提供する。
- 既存方式へ合わせる点: 実際のドラッグ成立判定は既存入力クラスに残し、trackerはゲーム固有の対象判定を重複実装しない。
- 採用しなかった案と理由: 生のマウス移動だけから判定すると、既存の長押しドラッグを検出できず、ゲーム上ドラッグ不能な場所での押下移動も誤検出する。
- Scene / Node / Resource / Autoloadの所有関係: マウスドラッグ状態はScene切替を越えて一意な入力状態なのでAutoloadが所有し、各ドラッグ入力Nodeとツールチップが明示API・signalを利用する。

## 影響範囲

- Authoring変更: 固定Scene構造の変更なし。
- Runtime変更: 敵・夢の種ドラッグ開始／終了通知と、ツールチップ表示抑制を追加する。
- Data / Serialization: 変更なし。
- ProjectSettings / InputMap: `MouseDragState` Autoloadを追加する。InputMap変更なし。
- 互換性 / Migration: 保存データ・Resource・Scene UIDへの影響なし。

## 実装 TODO

- [ ] `res://systems/input/mouse_drag_tracker.gd` に所有者単位で待機／ドラッグ状態を管理する型付きAPIとsignalを実装する。
- [ ] `project.godot` に `MouseDragState` Autoloadを追加する。
- [ ] `GameInputController` と `SeedButton` の既存ドラッグ開始・終了・破棄経路からtrackerへ通知する。
- [ ] `LeftTooltip` と `SeedTooltip` でドラッグ開始時の非表示と、ドラッグ中の表示拒否を実装する。
- [ ] tracker状態遷移と各ツールチップの表示抑制を独自テストへ追加する。

## 検証 TODO

- [ ] `git diff --check` と差分scopeを確認する。
- [ ] project標準のformat/lintを確認する（未設定なら明記する）。
- [ ] Godot headless importを実行する。
- [ ] 変更GDScriptのparseを実行する。
- [ ] `tests/mouse_drag_tracker_test.gd` と `tests/tooltip_layer_test.gd` を実行する。
- [ ] `res://scene/main/main.tscn` をheadless起動し、初期化errorがないことを確認する。
- [ ] 敵・夢の種のドラッグ中にツールチップが閉じて再表示されないことを操作確認する。
- [ ] log全文から新規errorがないことを確認する。

## リスクと切り分け

- Risk: ドラッグ終了通知漏れで状態が残る。
  - Detection: 所有者の重複・複数登録・終了順・tree離脱をテストする。
  - Mitigation: 終了処理と `_exit_tree()` の双方から冪等に解除する。
- Risk: Autoload初期化前後の参照error。
  - Detection: import、変更Script parse、Main Scene smokeで確認する。
  - Mitigation: `project.godot` のAutoload順と、Main Sceneより先に生成される契約を利用する。

## 完了時の報告事項

- 変更内容
- 実行した検証commandと対象
- failureと解消内容
- 未検証事項と残リスク
