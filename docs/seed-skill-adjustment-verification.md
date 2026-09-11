# 夢の種スキル調整・検証記録

2026-09-11。対象仕様: `data/resources/prompt.md` の25項目。比較基準: `4dee0ba1`。Godot 4.6.2 stable、GDScript、Main Scene は `scene/main/main.tscn`。

## 変更と設計

既存の SeedEffect Resource と resolver を拡張し、調整値は `data/resources/seeds/skills/*.tres` に保存した。倍率は1を基準とする直接乗算へ移行し、既存の加算スタックは resolver 内で倍率から増減分を取り出して維持する。仕様で変更指定のない効果は、変更前の実際の Resource 値による計算結果を維持した。

ステージ限定状態は `seed_skill_state.gd`、日をまたぐ100106の蓄積と一日の経過時間は `run_state.gd` に保持する。表示時刻と巻き戻らない経過時間を分け、`battle_info.gd`、`main.gd`、`game.gd` で受け渡す。共有定義Resourceへ試合中の蓄積を書き込まず、100124の消化時スナップショットは複製した効果に保存する。

| TODO | 実装・確認内容 |
|---|---|
| 1 倍率 | ダメージ・消化間隔などの倍率APIと保存値を移行。既存の重複計算を関連テストで確認 |
| 2 保存表示 | StatusLabelを11相当から6へ縮小。実描画で保存パスが1行に収まることを確認 |
| 3 100124 sub | 消化前の経過回数を消化時に固定。消化後に進行しても効果が増えない |
| 4 100105 sub | 自身の被ダメージ3倍、説明追記、累積被ダメージによる隣接配分 |
| 5 100106 main | 1時までの日終了で所持数ごとに+10%。日をまたいで蓄積し、遅れた日はリセット。現在値表示 |
| 6 100106 sub | 時刻を2時間戻す。可変の一日開始時刻で下限を制限 |
| 7 悪夢の巻戻し | 同じ開始時刻変数で下限を制限 |
| 8 100108 main | 夢の花が受ける消化ダメージ3倍。通常・追加ダメージの重複適用を防止 |
| 9 100112 main | ダメージ-20%を削除 |
| 10 100112 sub | 消化ライン+2、ステージ限定 |
| 11 100113 sub | 消化ライン内の悪夢へ胃袋X×Y×5ダメージ |
| 12 100114 sub | 胃袋端に接するモノへ1500ダメージ |
| 13 100115 sub | 胃袋を横に2マス拡張、ステージ限定 |
| 14 100117 main | 最大HPの3%×占有マス数を時間経過時に回復 |
| 15 100118 main | 実際に消化ダメージを受けたモノの数×5回復 |
| 16 100118 sub | 実際に消化ダメージを受けたモノの数×10回復。複数マスを同じモノとして数える |
| 17 100119 sub | 胃袋内で現在HPが最大のモノのHPを2.5倍にする |
| 18 100120 main | HP上限の蓄積は試合限定。重複と現在+%表示を確認 |
| 19 100121 sub | 隣接悪夢へプレイヤー最大HP×30ダメージ |
| 20 100122 sub | 隣接するモノへ一日の累積経過分×10ダメージ。120分→巻戻し→120分維持→60分進行→180分を確認 |
| 21 100123 main | 2時より前は間隔+60分、2時以降は-10分 |
| 22 100123 sub | 消化時刻が2時より前なら-20分、2時以降なら+120分。消化時に固定 |
| 23 100125 main | 吐き戻しコストを最大HPの10%にする |
| 24 100126 main | 吐き戻しコスト×10を悪夢へ与え、プレイヤーもコストを支払う。最後の悪夢撃破でもクリア通知前に支払う |
| 25 100126 sub | ドラッグ吐き戻し禁止、最終コスト2倍。スキルによる強制吐き戻しは処理する |

100123の「以前／以降」が重なる2時ちょうどは、既存の時刻境界に合わせて後半の効果を適用する。

## 検証コマンドと結果

実行バイナリは `C:\Program Files\Godot\Godot_v4.6.2-stable_win64.exe`。以下の `godot` はこのバイナリを指す。Python subprocessでプロセス終了を待ち、標準出力・標準エラーと終了コードを取得した。各実行は終了コード0。ただし後述の既存終了時エラーがあるため、ログ全体がエラーなしという意味ではない。

```text
godot --headless --path . --editor --quit
godot --headless --path . res://.godot/agent-logs/seed-parse-smoke.tscn --quit-after 120
godot --headless --path . res://tests/seed_skill_adjustment_test.tscn --quit-after 300
godot --headless --path . res://tests/dream_seed_description_contract_test.tscn --quit-after 120
godot --headless --path . --quit-after 120
godot --path . res://tests/seed_skill_adjustment_test.tscn --quit-after 300
git -c core.safecrlf=false diff 4dee0ba1 --check
```

- Importを実施。変更した56スクリプトをAutoload初期化後に明示ロードし、56件中失敗0。
- `SeedSkillAdjustmentTest`: headless・描画ありとも64チェック、失敗0。
- `DreamSeedDescriptionContractTest`: 失敗0。
- Main Sceneの120フレームsmokeを実施。
- 追加の関連確認は下表の9対象と上記説明契約テストの計10対象。すべて終了コード0、テスト失敗なし。

| 対象 (`res://tests/` 以下) | コマンド形式 |
|---|---|
| seed_100103_non_stacking_test.gd | `godot --headless --path . --script <対象>` |
| seed_100109_persistent_sub_effect_test.gd | 同上 |
| seed_100116_sub_stomach_size_test.gd | 同上 |
| game_seed_stomach_base_size_test.gd | 同上 |
| seed_resource_classification_test.gd | 同上 |
| stage_seed_pool_wiring_test.gd | 同上 |
| seed_100124_dynamic_description_test.tscn | `godot --headless --path . <対象> --quit-after 120` |
| debug_seed_parameter_panel_test.tscn | 同上 |
| debug_seed_retry_visual_test.tscn | 同上 |

実ゲームSceneで種の回転による隣接効果の解除・再適用、3回の出し入れ、消化後の効果が有効な状態からクリアして次の試合で解除されることを確認した。悪夢は既存の胃袋内回転禁止を維持し、回転要求が拒否されることを検証した。実描画のゲーム画面とデバッグパネルを画像で確認した（1600×900、640×360基準の拡大）。

ログは `.godot/agent-logs/seed-final-*.txt`、画像は同ディレクトリの `seed-adjustment-game.png` と `seed-adjustment-panel.png`。これらはローカル検証生成物で、変更対象に含めない。スクリプト読込用Sceneもローカル生成物。再現可能な挙動テストは `tests/seed_skill_adjustment_test.gd` と `.tscn` に保存している。

## エラー対応と残リスク

- 100117の保存浮動小数値が3%をわずかに超え、切上げで回復が1多くなる問題を0.03に修正した。
- 時間進行の接続過程で見つけた休憩時間の二重加算を修正した。
- 吐き戻しで最後の悪夢を倒すとHPコスト前にクリア通知する問題を修正し、通知時点のHPをテストで確認した。
- 古い100109・116テストの期待値は変更前でも実Resourceと不一致だったため、基準コミットの値を確認して修正した。指定外のスキル値を期待値に合わせて変更していない。
- 単独の `--check-only` ではAutoload `DebugState` の解決に失敗する対象があったため、Autoload初期化後の56スクリプト読込と実Sceneテストで確認した。
- `seed_catalog.tres` の既存UID警告（パス参照へフォールバック）と、終了時の `ObjectDB instances leaked` / `2～3 resources still in use at exit` が残る。変更前の `4dee0ba1` の隔離コピーでも再現した。verboseでは `novel_text_info.gd`、`stage_info.gd`、再生中音声Resourceなどが残留していた。今回UIDや無関係な終了処理は変更していない。基準ログは `baseline-import.txt`、`baseline-main.txt` などに保存。
- 標準入口として記載されている `scripts/Validate-Godot.ps1` / `validate-godot.sh` とformatter設定は存在しないため、上記の直接コマンドを使用した。スキルの検証報告テンプレートも存在しないため、本書に必須項目を記載した。
- 入力検証は実Sceneの入力ハンドラ・signalを使う自動試験。OSマウスによる手動通しプレイ、長時間のバランス確認、他解像度・他プラットフォームでの視覚確認は実施していない。
