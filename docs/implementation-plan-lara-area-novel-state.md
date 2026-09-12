# ラーラのエリア専用会話状態 実装計画

## 目的・受入条件

- ラーラとのその日最初の交流で、訪問済みかつ専用会話未再生のエリアがあれば、その専用会話を再生する。
- 専用会話対象エリアごとに `未訪問`、`訪問済み`、`再生済み` の3状態をenumで管理し、初期値を `未訪問` とする。
- 対象エリアへ一度ステージ選択で移動した時点で `訪問済み` とし、専用会話を選択した時点で `再生済み` とする。
- 複数の `訪問済み` エリアがある場合は、その中からランダムに1件を選ぶ。
- 同日2回目以降は従来どおり `false` 会話を再生し、エリア専用会話を再生しない。
- ラーラの訪問はプレイヤーのステージ選択ではなく、ラーラ予定の時刻・エリアを根拠に記録する。
- ステージ選択画面へ入るたび、前回記録した日・時刻から現在の日・時刻までにラーラが滞在した全エリアを訪問済みにする。
- 休息で日をまたいでも、間の予定を飛ばさず訪問済みにする。

## 現状と設計判断

- `Main._start_selected_stage_with_lara()` は、その日の初回交流時に `RunState.previous_area_stage` だけを調べ、未再生なら対応する専用会話を選んでいる。
- ラン中の交流履歴は `RunState` が所有しているため、新しいエリア別状態も `RunState` に置く。共有Resource、Scene、ProjectSettingsは変更しない。
- 対象エリアは既存専用会話があるコロッタ、エラミア、フェリス、ゴンサル、ミルネ、ネリクス、ザイカの7エリアに限定する。
- `LaraScheduleInfo` が日をまたぐ期間を分割し、`LaraDayInfo` が各消化予定とfallback滞在期間の交差から訪問エリアを返す。
- `RunState` が前回更新日・時刻を所有し、予定から得た対象エリアを `未訪問` から `訪問済み` へ進める。再生済み状態は後退させない。
- 訪問更新のruntime入口は `Main.show_stage_select()` とし、プレイヤーの `RunState.select_stage()` からはラーラ訪問状態を変更しない。

## 実装TODO

- [x] `scene/main/run_state.gd` に3状態enumと対象7エリアの状態Dictionaryを追加し、生成時と `reset()` 時に全件を `未訪問` へ初期化する。
- [x] `RunState.select_stage()` で対象エリアを初選択した際だけ `訪問済み` へ更新する。
- [x] `RunState` に専用会話候補の取得と `再生済み` 更新APIを追加する。
- [x] `scene/main/main.gd` の直前エリア判定を、訪問済み候補からのランダム選択へ置き換える。当日2回目以降の分岐は維持する。
- [x] 既存の交流・リセットテストを新状態契約へ更新し、未訪問、単一候補、複数候補、再生済み、同日2回目を検証する。
- [x] `LaraDayInfo` と `LaraScheduleInfo` に、開始日時から終了日時までの全滞在エリアを列挙するAPIを追加する。
- [x] `RunState` に前回訪問更新の日・時刻キャッシュを追加し、予定区間から訪問状態とキャッシュを更新する。
- [x] `Main.show_stage_select()` でラーラ進行同期後に訪問履歴を更新する。
- [x] `RunState.select_stage()` によるプレイヤー移動からラーラ訪問状態を更新しないよう修正する。
- [x] 6日目2時から7日目22時への日またぎでザイカ行政区を訪問済みにする回帰テストを追加する。

## 検証TODO

- [x] `git diff --check` と差分一覧で対象外ファイルを変更していないことを確認する。
- [x] Godot headless importと全GDScript parse testを実行する。
- [x] `tests/run_state_lara_test.gd`、`tests/lara_reward_test.gd`、`tests/main_lara_interaction_test.gd` を実行する。
- [x] `res://scene/main/main.tscn` をheadless smoke実行し、ログ全体に今回の変更に起因するparse/load/runtime errorがないことを確認する。
