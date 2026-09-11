# 日付変更時HP回復 Godot 実装計画

## 目的

- 連続プレイの有無にかかわらず、クリア画面ではクリア時刻によるHP回復を適用しない。
- クリア時刻によるHP回復は、その日の終了処理を経て日付が変わる時に一度だけ適用する。
- 夢の種による報酬選択時の回復と、種を放棄した時の追加回復は既存仕様を維持する。

## 受入条件

- [x] 非連続プレイの種選択時に、クリア時刻によるHP回復が発生しない。
- [x] 連続プレイの種選択時にも、クリア時刻によるHP回復が発生しない。
- [x] 日付更新時に、直前の時刻と装備中の種に応じた時間回復がHP上限を超えずに一度だけ適用される。
- [x] 「今日は休む」の押下時には回復せず、その後の日付更新時に回復する。
- [x] クリア画面のHP予測に時間回復を含めず、種選択・放棄によりその場で発生する回復だけを表示する。

## 現状調査

### Project

- Godot version: 4.6（`project.godot`）、検証バイナリは4.6.2 stable
- Script language: GDScript
- Main Scene: `res://scene/main/main.tscn`
- Test: `tests/*.gd` の独自SceneTree runner
- 標準検証スクリプト: リポジトリ内に `scripts/Validate-Godot.ps1` は未配置

### 現在の責務とデータフロー

- `StageClear._apply_selection_recovery()` が報酬選択時の回復を担当し、非連続プレイ時だけ時間回復を加算している。
- 連続プレイ時の「今日は休む」は `Main._on_stage_select_today_rest_requested()` から `StageClear.apply_time_recovery()` を直接呼んでいる。
- 実際の日付更新は `Main._advance_to_next_day()` が担当し、`RunState.current_day` と開始時刻を更新している。

## 設計判断

- 時間回復の適用責務を、日付更新を所有する `Main._advance_to_next_day()` へ移す。
- 回復対象は日をまたぐ状態の所有者である `RunState.current_hp` とし、クリア画面Nodeの状態に依存させない。
- 勝利後または「今日は休む」選択後だけ日付変更回復を予約し、既存の敗北時回復と二重適用しない。
- 回復率計算は既存の `StageClearCalculatorRecovery.get_clear_time_recovery_rate()` を再利用する。
- 報酬選択時には、夢の種の報酬効果と放棄追加回復だけを適用する。
- Scene、Resource、ProjectSettingsは変更しない。

## 実装TODO

- [x] `scene/main/stage_clear/stage_clear.gd` から報酬選択時の時間回復を除き、表示予測も即時回復分だけにする。
- [x] `scene/main/main.gd` で「今日は休む」押下時の直接回復を除き、日付更新直前に `RunState` へ時間回復を適用する。
- [x] `tests/continuous_play_test.gd` に、両プレイ方式のクリア画面非回復と日付更新時回復の契約を追加する。
- [x] `tests/stage_clear_status_preview_test.gd` の時間回復を含む表示期待値を新仕様へ更新する。

## 検証TODO

- [x] `git diff --check` と変更範囲を確認する。
- [x] Godot headless importを実行する。
- [x] 変更GDScriptをparseする。
- [x] `continuous_play_test.gd` と `stage_clear_status_preview_test.gd` を実行する。
- [x] Main Sceneをheadless smoke実行し、ログ全体に変更起因の新規errorがないことを確認する。

## リスク

- 日付更新前にエリア完了・4日目イベント・ラーラ勝負が挟まるため、回復を `_finish_current_day()` ではなく実際の日付更新直前へ置き、途中イベント中のHPを変更しない。
- 敗北時は戦闘側ですでに時刻別回復を行うため、日付変更回復の予約を解除して二重回復を防ぐ。
- 種の回復無効効果は、日付更新時点の装備状態を既存Calculatorへ渡して維持する。
- 作業開始時点の `data/resources/seeds/skills/seed_100_121.tres` と `resource/memo/enemy_shapes.md` の差分は対象外として保持する。
