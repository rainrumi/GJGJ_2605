# Godot 実装・検証規約

このファイルは、このリポジトリで AI エージェントが調査、計画、実装、修正、レビュー、検証、報告を行う際の常時適用ルールである。

下位ディレクトリにより具体的な `AGENTS.md` がある場合は、そのスコープ内では下位ルールを優先する。ユーザーの明示的な要求、リポジトリ内の確立済み規約、本ファイルの順で整合させる。ただし、検証結果の捏造、失敗の隠蔽、無関係な破壊的変更は許可しない。

## プロジェクト固有情報

導入時に以下を実態に合わせて更新する。推測で固定しない。

- Godot バージョン: `<project.godot または CI に合わせて記入>`
- スクリプト言語: `<GDScript / C# / 併用>`
- Main Scene: `<res://... または未設定>`
- テスト方式: `<GUT / GdUnit4 / WAT / 独自 runner / C# test / なし>`
- フォーマット・Lint: `<gdformat / gdlint / dotnet format / 独自 command / なし>`
- 標準検証コマンド: `./scripts/validate-godot.sh .`
- 主要ディレクトリ: `<例: scenes/, scripts/, resources/, addons/, tests/>`
- 設計資料: `docs/architecture.md`
- 検証資料: `docs/verification.md`

未記入項目は「自由に選んでよい」という意味ではない。対象コード、`project.godot`、CI、既存ドキュメントを調べ、確認できた事実に従う。

## 完了の定義

作業は、ファイルを変更した時点では完了しない。以下を満たした時点で完了とする。

1. 依頼と受入条件を満たす変更が行われている。
2. 既存の Scene、Node、Resource、signal、命名、依存方向と整合している。
3. import、GDScript parse または C# build、関連テスト、対象 Scene の実行確認を、変更内容に応じて実施している。
4. 実行したコマンドの終了状態と出力を確認し、変更に起因する error を残していない。
5. 実行できなかった確認、既存の無関係な失敗、残リスクを区別して報告している。

「コード上は正しそう」「末尾の成功メッセージだけ見た」「テスト環境がありそう」は検証結果として扱わない。

## 基本ワークフロー

1. `AGENTS.md`、関連する計画書、README、設計資料、CI 設定を読む。
2. `project.godot`、対象 Scene、継承元 Scene、関連 Script、Resource、Autoload、InputMap、テストを調べる。
3. 要求を、authoring変更、runtime変更、data変更、project設定変更、検証に分解する。
4. 既存方式で実現可能か確認し、変更範囲が最小になる案を選ぶ。
5. 実装と必要な Scene/Resource/ProjectSettings の変更を行う。
6. formatter/linter、import、parse/build、test、smoke run の順に検証する。
7. failure があれば原因を切り分け、修正後に影響する検証を再実行する。
8. 変更、検証証拠、未検証事項、残リスクを報告する。

実装計画を作る場合は `skills/godot-implementation-planner/SKILL.md`、実装または実装後確認には `skills/godot-implementation-check/SKILL.md` を使う。

## 意思決定の優先順位

設計や実装方法が複数ある場合は、次の順で判断する。

1. ユーザーが明示した要件と受入条件
2. 対象周辺で既に使われているパターン
3. リポジトリの設計資料、CI、テストが示す契約
4. Godot の Scene / Node / Resource / signal を活かした単純な構成
5. 新しい抽象、依存、Autoload、EditorPlugin の追加

新方式を導入するのは、既存方式では要件を満たせない理由、影響範囲、移行方法、検証方法を説明できる場合に限る。

## 変更範囲

- 変更は依頼された挙動と、その成立に必要な直接依存へ限定する。
- 無関係な命名変更、フォルダ移動、Scene再構成、全体リフォーマットを同時に行わない。
- 共通化の前に、同種処理が本当に複数存在し、変更理由が同じか確認する。
- 生成物、import cache、`.godot/`、ビルド成果物を、明確な理由なくコミット対象にしない。
- `.tscn`、`.tres`、`project.godot` を手編集する場合は、差分を限定し、Godotで再読込して構文と参照を確認する。
- Scene UID、Resource UID、外部Resource参照、NodePathを安易に書き換えない。

## Scene と Node の設計

- Scene は、可能な範囲で自己完結させ、親や特定の SceneTree 配置への暗黙依存を減らす。
- Scene root は、そのSceneの責務を表す型と名前にする。
- Node は engine lifecycle、描画、入力、物理、SceneTreeとの接続が必要な責務に使う。
- 純粋な計算、ルール、変換、データ構造を、理由なく Node にしない。既存方式に合わせて `RefCounted`、`Resource`、C# classなどを検討する。
- Sceneの子Nodeを外部Sceneから深いNodePathで直接操作しない。公開メソッド、signal、明示的参照を優先する。
- 既存Sceneの内部Node名を変更するときは、NodePath、animation track、signal connection、owner、unique name、継承Sceneへの影響を調べる。
- `%UniqueName`、`get_node()`、export参照など、参照取得方式は周辺実装へ合わせる。fallback検索を重ねて壊れたSceneを隠さない。

詳しい判断基準は `docs/architecture.md` を参照する。

## Scene authoring と Runtime生成

- 固定UI、固定カメラ、常設管理Node、手作業で調整するレイアウトは、原則としてSceneまたはResourceに保存する。
- `_ready()` で固定Nodeを大量生成し、Scene上の不足を補修しない。
- Runtime生成は、敵、弾、ドロップ、リスト項目、エフェクト、プロシージャル要素など、実行時に個数や内容が決まるものに使う。
- `PackedScene.instantiate()` を使う場合は、生成責務、親への追加、初期化、所有者、解放条件を明確にする。
- Editor上の設定不足を、`find_child()`、group検索、絶対パス検索、自動生成で無言補完しない。

## Resource とデータ

- 複数Sceneで共有する定義データ、調整値、構成データには、既存方式に沿って `Resource` を検討する。
- Runtime状態と共有定義Resourceを混同しない。共有Resourceを直接変更すると全利用箇所へ影響する可能性を考慮する。
- Resourceを複製すべきか共有すべきかを明示し、`resource_local_to_scene` や `duplicate()` を無根拠に追加しない。
- save data、設定、外部入力は信頼境界として扱い、型・範囲・欠損を検証する。
- `.tres` や `.res` の参照変更後は、load errorと利用Sceneを確認する。

## 依存関係と通信

- 子から親または所有者への通知には signal を優先する。signal名は発生済みの事実を表す過去形を基本とする。
- 親から所有Nodeへの命令は、明確な公開メソッドまたはプロパティで行う。
- signal接続をEditorで管理するかコードで管理するかは、周辺Sceneの方式に合わせる。重複接続を作らない。
- groupは分類・探索の明確な契約がある場合に使い、型や依存注入の代用品として乱用しない。
- Autoloadは、Sceneをまたぐ寿命、全体で一意な責務、明確な初期化順序が必要な場合に限る。便利という理由だけで追加しない。
- Autoloadを追加・変更する場合は、`project.godot`、起動順、テスト隔離、終了処理への影響を検証する。

## 必須参照、任意参照、エラー処理

- 必須のNode、Resource、設定値は契約として表現し、欠損時に原因が分かる形で失敗させる。
- 必須参照の欠損を、無言return、空の代替値、広範囲な `get_node_or_null()`、SceneTree全体検索で隠さない。
- 任意参照は変数名、export group、コメント、ドキュメントで任意であることを明示し、その場合だけ欠損分岐を設ける。
- 外部データ、save data、network入力、ユーザー生成コンテンツは検証対象とし、異常値でengine errorを連鎖させない。
- `assert` は開発時契約の検出に使い、ユーザー入力や回復可能な運用エラーの処理には使わない。
- error logには、何が不足し、どのScene/Resource/設定を直すべきか含める。

## GDScript

既存規約がない場合はGodotの公式スタイルへ合わせる。

- ファイル、関数、変数、signal: `snake_case`
- class_name、class、Node名、enum名: `PascalCase`
- 定数、enum member: `CONSTANT_CASE`
- signalは原則として過去形で命名する。
- public API、export変数、signal、関数の引数・戻り値には、合理的な範囲で静的型を付ける。
- `Variant`、未型付けArray/Dictionary、文字列ベースの呼び出しは、動的性が要件である場合に限定する。
- `_process()`、`_physics_process()` を常時有効にする前に、signal、Timer、Tween、AnimationPlayer、入力callbackで代替できないか確認する。
- engine callback、公開API、private helper、signal handlerの順序は周辺ファイルに合わせる。
- コメントは理由、契約、非自明な制約を書く。コードの逐語説明や変更履歴を書かない。

## C# / Godot .NET

- 対象プロジェクトがC#を使用している場合だけ適用する。
- nullable、analyzer、formatter、言語バージョンは既存 `.csproj`、`.editorconfig`、CIに従う。
- Node lifecycleと純粋なドメインロジックを可能な範囲で分離する。
- exported property、signal、NodePath、Resource型の変更では、Scene serialization互換性を確認する。
- GodotObjectの寿命と通常の.NET objectの寿命を混同しない。解放済みobject、event購読、CancellationTokenの扱いを明確にする。
- C#変更後はGodotのsolution buildまたはプロジェクト標準の`dotnet build/test`を実行する。

## Lifecycle、入力、非同期

- `_enter_tree()`、`_ready()`、`_exit_tree()` の責務を区別する。初期化順序への依存を増やさない。
- 物理状態は原則として `_physics_process()`、描画フレーム依存処理は `_process()`、入力は用途に応じて `_input()` / `_unhandled_input()` / ControlのGUI入力を使う。
- 毎フレーム探索、毎フレームNode取得、毎フレームResource loadを追加しない。
- `await` 後には、対象Nodeがtree内に存在するか、状態遷移が有効か、キャンセル相当の条件が必要か確認する。
- Scene切替、queue_free、signal待機、Timer待機を跨ぐ非同期処理では、寿命切れを想定する。
- Tween、AnimationPlayer、Timerなど既存のengine機能で表現できる処理に、独自のフレームカウンタを増やさない。

## UI

- 既存のControl階層、Container、Theme、focus、input方針へ合わせる。
- Container配下のControlを、runtimeで固定座標へ補正してlayout契約を破らない。
- 表示文言をコードへ直接埋め込む前に、既存のLocalization方式を確認する。
- UI状態とゲーム状態を一つの巨大Scriptへ混在させない。既存のPresenter/ViewModel/Controller方式があれば従う。
- UI変更は対象解像度、stretch設定、anchor、size flags、focus navigation、mouse/filterを確認する。

## ProjectSettings、InputMap、Plugin

- `project.godot`、InputMap、Autoload、rendering、physics、layer、display設定の変更は、コード変更より広い影響を持つものとして扱う。
- 設定変更の理由、旧値、新値、影響するplatformまたはSceneを記録する。
- 既存Input actionを再利用できるか確認し、同義actionを増やさない。
- addonやEditorPluginを追加・更新する前に、ライセンス、Godot対応版、既存設定、CI環境を確認する。
- `@tool` scriptはEditor起動時にも動作するため、副作用、ファイル書込み、Scene変更を特に慎重に扱う。

## 検証契約

変更内容に応じて、次の検証を実行する。

1. **差分確認**: 意図しないファイル、import生成物、UID変更がないか確認する。
2. **Format / Lint**: プロジェクト標準コマンドが存在する場合は実行する。
3. **Import**: Godot editor binaryでresource importを完了させ、load/import errorを確認する。
4. **Parse / Build**: 変更したGDScriptをparseし、C#利用時はsolutionをbuildする。
5. **Automated Test**: 変更に近いテストを優先し、可能なら関連suite、全体suiteへ広げる。
6. **Runtime Smoke**: 対象SceneまたはMain Sceneを起動し、初期化と主要導線でruntime errorがないことを確認する。
7. **Visual / Interaction**: UI、animation、physics、rendering変更では、headlessだけで十分とみなさず、必要な目視・入力確認を行う。
8. **Log Review**: exit codeだけでなく、出力全体からparse error、script error、resource load failure、runtime exceptionを確認する。

標準入口は `scripts/validate-godot.sh` または `scripts/Validate-Godot.ps1` とする。プロジェクト固有テストやformatterは `.agent/godot-agent.env` で接続できる。

`--check-only` は指定Scriptのparse確認であり、プロジェクト全体の正常性を証明しない。headless smoke runも視覚的正しさを証明しない。各手段の検出範囲を理解して組み合わせる。

## Failure の扱い

- 変更に起因するfailureは、原因を特定して解消するまで完了扱いにしない。
- 既存failureか新規failureか不明な場合は、変更前後、対象path、時刻、再現手順、git差分から切り分ける。
- 無関係な既存warningは勝手に修正しない。ただし検証の信頼性や今回の挙動へ影響する場合は報告する。
- tool未導入、Godot binary不在、必要asset不在、外部service不通などはblockerとして具体的に報告する。
- 検証していない項目を「問題なし」と書かない。

## 報告契約

最終報告には、最低限次を含める。

- **変更**: 変更した挙動と主要ファイル
- **判断**: 採用した設計と、既存方式へ合わせた点
- **検証**: 実行したコマンド、対象Scene/test、結果
- **エラー対応**: 発生したfailureと解消内容
- **未検証・残リスク**: 実行できなかった確認と理由

成功報告は証拠に対応させる。「テスト済み」と書く場合はテスト名またはコマンドを示す。「実行確認済み」と書く場合はSceneまたは導線を示す。

## 禁止事項

- 調査せずにUnity風、Web風、別プロジェクト風のアーキテクチャを持ち込む。
- 壊れたScene参照をruntime検索や自動生成で隠す。
- 必要性を説明できないAutoload、global state、service locatorを追加する。
- `project.godot`、`.tscn`、`.tres` を大規模に再保存し、無関係な差分を混ぜる。
- import、parse/build、test、runtime確認を実施せず、実施したように報告する。
- ログの末尾や成功件数だけを見て、途中のerrorを無視する。
- ユーザーの依頼と無関係な既存コードを「ついでに」修正する。
