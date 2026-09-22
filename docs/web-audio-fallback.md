# unityroom向けWeb音声フォールバック

## 背景

unityroomのGodot 4.6.2共有ランタイムは、`godot.audio.worklet.js` と
`godot.audio.position.worklet.js` を `application/octet-stream` で配信する場合がある。
ブラウザはAudioWorkletのmodule scriptに厳格なMIME判定を行うため、GodotのStream再生と
Sample再生はどちらも開始できない。

## 採用方式

- Web版だけ `audio/driver/driver.web="Dummy"` とし、失敗するGodot AudioWorkletを起動しない。
- `WebAudioFallback` AutoloadがMP3 Resourceのdataをdata URIへ変換し、ブラウザ標準の
  `HTMLAudioElement` で再生する。
- WindowsなどWeb以外では従来どおり`AudioStreamPlayer`を使用する。
- BGMは1要素、SEは既存AudioStreamPlayerに対応する論理channelごとに1要素を保持する。
- 音量は既存の`GameSettings`に従い、MasterとBGM/SEカテゴリの積を適用する。

Autoloadが必要なのは、BGMと音量設定をSceneの寿命を越えて一意に管理し、各Sceneから同じ
ブラウザ音声要素へアクセスするためである。

## 削除条件

unityroomがAudioWorkletのJavaScriptを正しいJavaScript MIME typeで配信するようになり、
Godot標準のStreamまたはSample再生が実機で安定することを確認できた場合は、この
フォールバックとWeb限定Dummy driver設定を削除できる。
