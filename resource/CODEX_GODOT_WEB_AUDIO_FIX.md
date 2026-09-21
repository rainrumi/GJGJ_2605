# Codex向け修正指示書 — Godot Webビルド音声無音問題

## 目的

このGodotプロジェクトには、デスクトップ実行では音声リソースが読み込まれる一方、WebビルドではBGM・SEを含む音声全般が鳴らない問題がある。

unityroomへはGodotのWebエクスポートで生成される `Build.pck` のみをアップロードする運用を想定している。

今回の修正では、**WebビルドでBGM・SEが正常に再生される状態にすること**を目的とする。

---

## 調査済み事項

### 1. 音声リソースのパス自体は正常

現在のプロジェクトでは、以下のようなパスで音声を参照している。

```text
res://resource/sound/bgm/Night_Dance.mp3
res://resource/sound/se/se_attack.mp3
res://resource/sound/se/se_click.mp3
res://resource/sound/se/se_popopo.mp3
res://resource/sound/se/se_select.mp3
res://resource/sound/se/se_stage_clear.mp3
```

`tests/pck_content_test.gd` にも上記音声のPCK収録確認が存在する。

また、`export_presets.cfg` では以下が設定されている。

```ini
include_filter="resource/novel/**/*.txt,resource/sound/**/*.mp3"
```

既存ログでも `.mp3.import` がWebエクスポート時にPCKへ保存されていることを確認済み。

したがって、**今回の主原因を単純な `res://` パス間違い・MP3未収録とみなして大規模なResource化やファイル移動を行わないこと。**

---

### 2. 問題の中心はWeb用Playback Typeの可能性が非常に高い

現在の `project.godot` には以下の設定がある。

```ini
[audio]

general/default_playback_type.web=1
```

Godot 4.6のProjectSettingsでは、

- `audio/general/default_playback_type = 0` → Stream
- `audio/general/default_playback_type.web = 1` → Sample

という設定になっている。

Godot公式Issue #119026では、Godot 4.3以降のWebエクスポートで、

- Web
- Sample playback
- 複数Audio Bus
- 特にsingle-threaded Web export

の組み合わせにより、Master Busが出力先から切断され、`AudioStreamPlayer.playing == true` のまま全音声が無音になる不具合が報告されている。

このプロジェクトではBGM/SE用の複数Busを利用しているため、条件が一致する。

参考:

- Godot Issue #119026  
  https://github.com/godotengine/godot/issues/119026
- Godot 4.6 ProjectSettings  
  https://docs.godotengine.org/en/4.6/classes/class_projectsettings.html
- Godot 4.6 AudioServer PlaybackType  
  https://docs.godotengine.org/en/4.6/classes/class_audioserver.html
- 関連Web音声Issue #117022  
  https://github.com/godotengine/godot/issues/117022

---

## 必須修正

### `project.godot`

以下を、

```ini
general/default_playback_type.web=1
```

から、

```ini
general/default_playback_type.web=0
```

へ変更すること。

これによりWebでもデフォルトの再生方式をSampleではなくStreamへ戻す。

**この変更が今回の本命修正。**

---

## テスト修正

### `tests/main_ui_click_se_test.gd`

現在このテストには、Web用Playback Typeが `1` であることを期待するアサーションが存在する。

概ね以下の条件:

```gdscript
ProjectSettings.get_setting(
    "audio/general/default_playback_type.web",
    -1
) == 1
```

修正後の仕様に合わせて、期待値を `0` に変更すること。

例:

```gdscript
ProjectSettings.get_setting(
    "audio/general/default_playback_type.web",
    -1
) == 0
```

アサーションメッセージもSample再生を要求する内容になっている場合は、**WebではStream再生を使用する**ことが明確になるよう更新すること。

---

## 変更してはいけないもの

今回の修正では、原因切り分けを維持するため以下を勝手に変更しないこと。

1. `resource/sound/` 配下のMP3ファイルの移動・リネーム
2. 全音声ファイルの `.tres` / 独自Resource化
3. AudioStreamPlayerの各シーンへの大量な個別 `playback_type` 上書き
4. BGM Bus / SE Bus構成の削除
5. `res://resource/sound/...` の参照パス変更
6. unityroom専用と称した独自ローダーの追加
7. JavaScriptによるWeb Audio API直接再生への置換
8. 音声システム全体のリファクタリング

まずは `audio/general/default_playback_type.web=0` への最小修正で解決させること。

---

## PCK / export設定について

unityroom公式ではGodot作品について、Web export後に生成された `Build.pck` をアップロードする方式が案内されている。

参考:

https://help.unityroom.com/Godot-Engine-381dc3ed5de980b2a573ccfe415feb52

したがって、このプロジェクトも **PCK単体の更新で成立する状態を維持すること。**

`export_presets.cfg` にある

```ini
include_filter="resource/novel/**/*.txt,resource/sound/**/*.mp3"
```

は現状維持でよい。

ただしCodex側で実際のPCK内容を確認できる場合は、以下の音声がexport対象になっていることを検証すること。

```text
res://resource/sound/bgm/Night_Dance.mp3
res://resource/sound/se/se_attack.mp3
res://resource/sound/se/se_click.mp3
res://resource/sound/se/se_popopo.mp3
res://resource/sound/se/se_select.mp3
res://resource/sound/se/se_stage_clear.mp3
```

---

## ブラウザAutoplay制限について

Webブラウザでは、ユーザー操作前の音声再生が制限される場合がある。

ただし今回の症状は「BGMだけ開始しない」ではなく、**SEを含む音全般が鳴らない**ものなので、Autoplay制限だけでは説明できない。

既存プロジェクトにユーザー入力後にBGMを開始する処理がある場合は、それを維持すること。

Autoplay対策を理由に今回のPlayback Type修正を削除しないこと。

---

## 検証項目

可能な範囲で以下を確認すること。

### 静的確認

- [ ] `project.godot` の `audio/general/default_playback_type.web` が `0`
- [ ] `tests/main_ui_click_se_test.gd` の期待値も `0`
- [ ] `resource/sound/` 以下のMP3が存在
- [ ] シーン上の `res://resource/sound/...` 参照が壊れていない
- [ ] `export_presets.cfg` が音声ファイルを除外していない
- [ ] `tests/pck_content_test.gd` の音声チェックが維持されている

### Godotテスト

Godot CLIが利用可能なら、既存テスト群のうち少なくとも以下を実行すること。

- `tests/main_ui_click_se_test.gd` に対応するテスト
- `tests/pck_content_test.gd`
- BGM Bus関連テスト
- SE関連テスト
- GDScript parseテスト

プロジェクト既存のテスト実行方法がある場合は、それを優先する。

### Web export

Web export templateが利用可能ならWebビルドを生成し、exportログ上で音声リソースがPCKへ収録されることを確認する。

特に以下のような `.mp3.import` の保存が存在することを確認する。

```text
res://resource/sound/bgm/Night_Dance.mp3.import
res://resource/sound/se/se_click.mp3.import
```

### ブラウザ実機確認が可能な場合

ユーザー操作後に以下を確認する。

- BGMが鳴る
- UIクリックSEが鳴る
- 選択SEが鳴る
- 戦闘SEが鳴る
- ステージクリアSEが鳴る
- 音量設定が反映される
- Chrome系 / Firefox系の少なくとも一方で確認

---

## 追加調査が必要になる条件

`general/default_playback_type.web=0` に変更してもWeb実機で無音の場合のみ、次の調査へ進むこと。

優先順位は以下。

1. 実際に生成されたPCKに音声import resourceが含まれるか
2. Browser ConsoleにWebAudio / resource loadエラーがないか
3. AudioServerのBus数・Bus名・send先
4. `AudioStreamPlayer.bus` が存在しないBus名を指していないか
5. 音量設定が `-80 dB` / muteになっていないか
6. ユーザー入力前だけ再生して停止していないか
7. 個別AudioStreamPlayerで `playback_type` がSampleに強制されていないか

この段階でも、推測で大規模変更を入れず、ログまたは再現結果を根拠に修正すること。

---

## 完了条件

以下を満たしたら作業完了。

1. `project.godot`
   - `audio/general/default_playback_type.web=0`
2. `tests/main_ui_click_se_test.gd`
   - Web Playback Typeの期待値が `0`
3. 音声リソースの既存パス・Bus構成を破壊していない
4. 既存テストで新規エラーを発生させていない
5. 可能ならWeb exportが成功する
6. 最終報告に以下を書く
   - 変更ファイル
   - 変更内容
   - 実行したテスト
   - Web exportの成否
   - 実ブラウザ確認の有無
   - 未確認事項

---

## Codexへの重要指示

**修正範囲を広げすぎないこと。**

今回の既知不具合に対する第一修正は、

```ini
audio/general/default_playback_type.web=0
```

への変更である。

音声Resourceの配置やPCKへの収録には既に正常性を示す材料があるため、まずこの最小差分を実装・検証すること。

検証で反証された場合のみ追加修正へ進むこと。
