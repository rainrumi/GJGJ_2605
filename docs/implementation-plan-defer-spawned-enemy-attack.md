# 寄生型悪夢の生成ターン攻撃抑止 実装計画

## 目的と受入条件

- 胃袋内の経過分数が0の悪夢は通常攻撃を行わない。
- 悪夢個体の経過分数には、固定30分ではなく、そのターンに解決された消化間隔を加算する。
- 既存の消化間隔補正、敵攻撃補正、生成処理を維持する。

## 調査結果と設計判断

- 個体の経過分数は `EnemyStomachStatus.elapsed_minutes` が所有する。
- `Game` はターン開始時に `EnemyTurnProcessor.get_step_minutes()` で動的な消化間隔を算出している。
- 現状の `begin_turn()` は算出前に固定の `_step_minutes` を加算しているため、ターン開始処理自身が動的間隔を返し、同じ値を個体状態と後続の消化処理に渡す。
- 生成された寄生型悪夢は同一ターンの攻撃解決まで `elapsed_minutes == 0` のため、攻撃Resolverで通常攻撃対象から除外する。新しい敵種別やAutoloadは追加しない。

## 実装TODO

- [x] `EnemyTurnProcessor.begin_turn()` で敵効果を更新後に動的消化間隔を一度だけ算出し、行動可能な悪夢の経過分数とBattleClockへ同値を適用して返す。
- [x] `EnemyController.apply_turn_start_effects()` と `Game` を、返された消化間隔を後続処理に使用する契約へ更新する。
- [x] `EnemyController.process_turn()` は入力済みの動的消化間隔を `begin_turn()` に渡し、重複計算を避ける。
- [x] `EnemyAttackResolver` で `elapsed_minutes <= 0` の悪夢を通常攻撃から除外する。
- [x] 動的間隔の加算と、経過0の悪夢が攻撃しない回帰テストを追加する。

## 検証TODO

- [x] 変更したGDScriptのparse確認を行う。
- [x] 追加した回帰テストと関連する敵Controllerテストを実行する。
- [x] 標準検証入口の有無を確認し、Godot 4.6.2でimportとログ確認を行う。
- [x] Main Sceneをheadlessでsmoke実行し、今回の変更に起因する初期化・resource load errorがないことを確認する。

## 影響と残リスク

- Scene、Resource、ProjectSettings、save data形式は変更しない。
- `elapsed_minutes` は胃袋内で行動可能だった実経過分を表し、生成直後の個体だけが0のまま同一ターンの攻撃から除外される。
