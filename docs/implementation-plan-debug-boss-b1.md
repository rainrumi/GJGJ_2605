# デバッグボスB-1選択 Godot 実装計画

## 目的

- ステージ選択のデバッグ用ボス一覧から選んだエリアを、通常ボスと同じステージ仕様のB-1編成で開始する。

## 受入条件

- [x] ボス絞り込み中に選択した5エリアは、それぞれの `strengthened_enemy_presets[0]` で開始する。
- [x] 通常のボス選択は既存の進行番号を参照し続ける。
- [x] デバッグ選択によって通常・ボスの進行データを変更しない。
- [x] B-1定義が欠損している場合は、対象エリアが分かるエラーを出して戦闘を開始しない。

## 現状調査

### Project

- Godot version: 4.6.2
- Script language: GDScript
- Main Scene: `res://scene/main/main.tscn`
- Autoload: `DebugState` ほか
- Test / CI: 独自のSceneTree/Sceneテスト。標準検証Scriptは未配置。

### 関連ファイル

- Scene: `res://scene/main/main.tscn`, `res://scene/main/stage_select/stage_select.tscn`
- Script: `res://scene/main/main.gd`, `res://scene/main/stage_select/stage_select.gd`, `res://scene/main/run_state.gd`
- Resource / Data: `StageInfo.enemy_data.strengthened_enemy_presets`
- ProjectSettings / InputMap: 変更なし

### 現在の責務とデータフロー

- `StageSelect` が選択した `StageInfo` をsignalで通知し、`Main` が `RunState` に保持する。
- `Main._create_battle_start_context()` が `RunState.pick_enemy_preset()` で通常の進行位置に対応する敵編成を決定する。
- ボス絞り込みは高難度Stageを作るが、B-1固定の選択意図をMainへ通知していない。

## 確定事項

- B-1は各Stageの `enemy_data.strengthened_enemy_presets[0]` である。
- 通常ボスは `RunState.strengthened_enemy_preset_indices` に従ってB-1以降へ進む。

## 仮定・未確定事項

- 「同じ仕様」は敵編成だけを複製せず、通常ボスと同じStage、ノベル、HP、報酬、クリア導線を使用する意味とする。

## 設計判断

- 採用案: ボス絞り込み選択専用signalをMainへ送り、B-1の既存Presetを次の戦闘開始Contextに一度だけ指定する。
- 既存方式へ合わせる点: Mainの通常ステージ選択共通処理とBattleInfo生成を通す。
- 採用しなかった案と理由: RunStateの進行値を0へ変更する案は保存対象の進行を破壊するため採用しない。
- Scene / Node / Resource / Autoloadの所有関係: UI状態はStageSelect、戦闘開始時の一時PresetはMain、永続進行はRunStateが所有する。

## 影響範囲

- Authoring変更: Main Sceneへ専用signal接続を追加する。
- Runtime変更: ボス絞り込み選択時だけB-1Presetを一度指定する。
- Data / Serialization: 変更なし。
- ProjectSettings / InputMap: 変更なし。
- 互換性 / Migration: 既存 `stage_selected` signalは維持するため移行不要。

## 実装 TODO

- [x] `stage_select.gd` がボス絞り込み中の選択を専用signalで通知する。
- [x] `main.gd` がB-1Presetを検証し、通常のステージ開始処理へ渡す。
- [x] `main.tscn` に専用signal接続を保存する。
- [x] 選択結果と進行非破壊を検証するテストを追加する。

## 検証 TODO

- [x] `git diff --check` と差分scopeを確認する。
- [x] Godot headless importを実行する。
- [x] 変更GDScriptをparseする。
- [x] `main_debug_boss_selection_test.gd` と関連テストを実行する。
- [x] `res://scene/main/main.tscn` をheadless起動する。
- [x] 実行出力から新規errorがないことを確認する。

## リスクと切り分け

- Risk: 専用Presetがノベル待機中に失われる。
  - Detection: Main経由のテストで戦闘開始後のPresetを確認する。
  - Mitigation: 一時PresetはBattleInfo生成完了時までMainが保持する。

## 完了時の報告事項

- 変更内容
- 実行した検証commandと対象
- failureと解消内容
- 未検証事項と残リスク
