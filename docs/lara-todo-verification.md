# ラーラ関連TODO 実装・検証（2026-09-09）

状態: 完了。resource/TODO.mdと追加仕様を実装した。

## 変更

- `data/info/rara/` と `data/resources/rara/lara_schedule.tres`: 全体・各日・各時間帯を型付きResourceで管理する。acid_mater.txtの20日分を44個の消化予定へ固定配置した。
- `scene/main/run_state.gd`: 日付・時刻からラーラの累積消化数と滞在エリアを再計算する。プレイヤー消化数は通常・ボスを含むステージ勝利数。
- `scene/main/main.gd`: 交流、初回報酬、4日ごとのボス後勝負、勝敗別報酬、エンディング分岐を既存NovelFlowへ接続した。
- `scene/main/stage_select/`: HP右側に消化数を表示する。4日目終了のラーラ解放前はティーナのみ、解放後はラーラとティーナを2段表示する。
- `data/resources/novel/novel_ending_{true,normal,bad}.tres`: 新しい3エンディングを設定し、旧gameclear本文を外した。

## 予定Resourceの契約

`lara_schedule.tres` の `days[0]` が1日目。各 `digestions` は終了時刻順で、`end_hour/end_minute`、滞在 `area`、終了時に増える `digestion_count`（標準1）を持つ。`fallback_area` は最後の予定の翌分から朝6時までの滞在先。終了時刻と同じ分に加算し、翌分から次のエリアへ移る。各日の最終加算は3:00〜5:05。

共有Resourceは実行時に変更しない。RunStateが現在値を再計算するため、画面再表示で二重加算されず、休息で日を飛ばしても前日分を含む。ラーラ登場前の1〜4日目も消化数は進む。

## 挙動

- 交流: ステージ前ノベル→ラーラ交流→初回報酬文→戦闘。前エリアがコロッタ、エラミア、フェリス、ゴンサル、ミルネ、ネリクス、ザイカで未読なら対応areaを優先。エルメナは対象外。未該当はcommon 001〜008、同日2回目以降はfalse 001。
- 初回報酬: HP回復33%（50/80/100%を等確率）、夢の種67%。出現プールから種IDを重複排除し、既存所持制限を適用して所持枠へ追加。
- 勝負: 4日ごとのボス勝利後、通常報酬→エリア完了ノベル→4日目初登場イベント→setup→勝敗ノベル→報酬文→翌日。勝ち=レア、引き分け=全出現種、負け=通常を均等抽選。HP不足時は全回復。
- エンディング: 旧市街ボス3勝以上を最優先でtrue、次に全ステージ25勝以上でnormal、それ以外はbad。

## 検証

Godot 4.6.2を使用。ログは `.godot/agent-*.log`。

| 対象 | 結果 |
|---|---|
| `git diff --check` | 成功 |
| headless import | exit 0 |
| `all_gdscript_parse_test.gd` | exit 0、parse/compile失敗なし |
| `lara_schedule_test.gd` | exit 0、0 failures |
| `lara_reward_test.gd` | exit 0、0 failures |
| `main_lara_interaction_test.gd` | exit 0、0 failures |
| `main_lara_judge_test.gd` | exit 0、0 failures |
| `run_state_lara_test.gd` | exit 0 |
| `main_first_nightmare_event_test.gd` | exit 0 |
| `main_stage_selection_novel_test.gd` | exit 0 |
| `main_lara_visual_test.gd` | exit 0、0 failures。解放前のティーナ単独表示、解放後の2段表示、640×360、1280×720、報酬文を非headless描画確認 |
| Main Scene smoke | exit 0 |

目視でHPの子Labelと消化数が重なる問題を検出し、消化数の左端を164pxへ修正して両解像度で再確認した。

## 既存failure・未検証

- 全実行の終了時にResource残留エラーがある。`git archive HEAD`の変更前コピーでもMain smokeは同じ3Resource、既存RunStateテストも同じ2Resourceが残るため、今回の変更起因ではない。新規ResourceはMainの残留一覧にない。
- `continuous_play_test.gd` は既存の「LocationLabelを上へ移動する」が失敗する。変更前コピーでも同一失敗を確認し、今回の対象外として未修正。
- seed Resourceには既存invalid UID警告があり、text pathで読み込まれる。今回UID参照は変更していない。
- 標準検証script、formatter/linter、export presetは未配置。製品exportへの拡張子なしシナリオ同梱と、全20日の手動通しプレイは未検証。
