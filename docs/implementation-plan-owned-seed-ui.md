# 所有種パネル・通常時装備種UI 実装計画

## 目的と受入条件

- `OwnedSeedPanel` を640×360基準で左端30%（192px）・全高360pxの半透明パネルへ変更する。
- パネル外枠をなくし、閉じるボタンを左上へ配置する。
- 装備6枠（3列×2行）と所持16枠（4列×4行）を30px角・間隔10pxで統一し、種あり枠は完全不透明の`#f0e0ff`、空き枠は透明背景と1pxの`#f0e0ff`縁、夢の種テクスチャは黒色で表示する。
- 所持枠はパネル左右から約20px離し、装備枠はパネル中央へ揃える。
- 装備枠の下端と所持枠の上端の間へ、見出しを含む30px以上の縦余白を設ける。
- 装備・所持見出しへhoverしたとき、それぞれの効果対象とドラッグ時のサブスキル発動条件をツールチップで説明する。
- 所有種パネルを閉じた通常時も、装備中の最大6種をキャラクター頭頂部付近へ3列×2行で表示する。
- 通常時は可視枠を描画せず、薄いピンクの種テクスチャと透明な30px角の当たり判定で既存ツールチップ・回転・ドラッグを利用できる。
- 所有種パネルを開くと通常時装備種UIを非表示にし、閉じると再表示する。

## 調査できた現状

- Godot 4.6、GDScript、640×360、`canvas_items` stretch。Main Sceneは`res://scene/main/main.tscn`。
- `game.tscn` の`UI/SeedButtonList`が通常時装備表示、`UI/OwnedSeedPanel`が所有種パネルを所有する。
- `BattleUI`が両表示へ同じ装備配列を渡し、パネル開閉時に排他的な`visible`切替を行っている。
- `SeedButtonList`が`SeedButton`をruntime生成し、各`SeedButton`がツールチップ、短押し回転、長押し・移動ドラッグを所有する。
- 既存の`dream_seed_inventory_test.gd`はパネル、通常表示、開閉、ツールチップ、編成、ドラッグを検証し、環境変数指定で画面キャプチャを保存できる。
- formatter/linter設定と実体のある標準検証Scriptは未配置。独自SceneTreeテストをGodot CLIで実行する構成。

## 設計判断

- 既存の`SeedButtonList` / `SeedButton`とsignal契約を再利用し、新しいUI管理NodeやAutoloadは追加しない。
- 固定のパネル寸法・配置・背景は`.tscn`へ保存し、種ボタンだけ既存どおりruntime生成する。
- 枠サイズは「1.3倍程度」より「所持枠の左右余白約20px」と整数pixelの均一な10px間隔を優先する。`(192 - 20×2 - 10×3) / 4 = 30.5`から30px角・左右21pxとする。
- 装備・所持枠の見た目は共通`SeedButton` Sceneへ置き、通常表示では既存の`frame_visible = false`で透明な当たり判定だけ残す。
- 通常表示の薄いピンクは`BattleUI`の表示色だけを変更し、パネル内の黒色指定とは分離する。
- ProjectSettings、InputMap、Resourceデータ、保存形式は変更しない。

## 実装TODOと対応する検証TODO

### 工程1: OwnedSeedPanel

- [x] `owned_seed_panel.tscn`を192×360、左上閉じるボタン、外枠なし・背景alpha 0.3へ変更する。
- [x] `seed_button.tscn` / `seed_button.gd`と`seed_button_list.*`を30px角・間隔10pxへ揃え、種あり枠を完全不透明の`#f0e0ff`、空き枠を透明背景と1pxの`#f0e0ff`縁にする。
- [x] 装備リストを幅110pxで中央、所持リストを幅150px・左右21pxへ配置し、両リスト間へ見出しを含む30px以上の余白を設けてページ操作が収まるよう調整する。
- [x] `game.tscn`のパネルinstanceを左端0px、上端0px、幅192px、高さ360pxにする。
- [x] `dream_seed_inventory_test.gd`へ寸法、余白、間隔、色、枠線なしの回帰検証を追加する。
- [x] 関連testとキャプチャを実行し、640×360で配置と重なりを確認する。

### 工程2: 通常時装備種UI

- [x] `game.tscn`の通常表示をキャラクター中心X=95付近、頭頂部Y=54付近の3列×2行へ配置する。
- [x] `battle_ui.gd`の通常時アイコン色を薄いピンクへ変更し、frame非表示を維持する。
- [x] `dream_seed_inventory_test.gd`へ6個表示、30px透明当たり判定、薄いピンク色、ツールチップ、パネル開閉時の排他表示を追加する。
- [x] 関連test、対象Scene smoke、開閉両状態のキャプチャを実行し、キャラクター・他の種・主要UIとの重なりを確認する。

## 検証手順

1. `git diff --check`と変更ファイル一覧を確認する。
2. 利用可能なGodot 4.6 binaryでheadless importを実行する。
3. 変更GDScriptと`tests/all_gdscript_parse_test.gd`をparse/testする。
4. `res://tests/dream_seed_inventory_test.tscn`を実行する。
5. `res://scene/main/game/game.tscn`をheadless smoke実行する。
6. `DREAM_SEED_CAPTURE_PATH`、`DREAM_SEED_EMPTY_CAPTURE_PATH`、`DREAM_SEED_CLOSED_CAPTURE_PATH`で640×360画像を保存し目視する。
7. ログ全文を`SCRIPT ERROR:`、`Parse Error:`、`ERROR:`、`Failed loading resource`、`Invalid call`、`Exception`、`FAILED`で検索する。

## 未確定事項・切り分け

- 「透明度30%」は背景alpha 0.3として扱う。見た目が薄すぎる場合はキャプチャを根拠にalphaのみ再調整する。
- 通常表示はキャラクター画像の頭頂が概ねY=60のため、最上段Y=54を初期値とする。ステージ情報や種ボタンとの重なりがあればキャプチャで座標だけを調整する。
- Godot binaryが見つからない場合、Scene/Scriptの静的差分確認までは行い、import・test・smoke・キャプチャを未検証として明示する。
