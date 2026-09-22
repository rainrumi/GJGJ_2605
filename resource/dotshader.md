# Shader 修正仕様書

## 1. 目的

現在の CanvasItem shader は、上端の波形を `vertex()` でメッシュ頂点変形している。

これを廃止し、

**メッシュ形状は一切変更せず、fragment shader 内で以下をピクセル単位に生成する方式へ変更する。**

- 上端の正弦波境界
- 上端の1px波線
- 内部の斜線ハッチ
- 元テクスチャによるマスク

描画は原則として **ローカルテクスチャ座標系**で完結させること。

---

## 2. 削除する処理

以下は完全に削除する。

```glsl
varying vec2 world_position;
varying vec2 world_origin;
varying vec2 world_scale;
```

頂点変形も削除する。

```glsl
void vertex() {
    ...
    VERTEX.y += ...
}
```

特に `VERTEX` の値は一切変更しないこと。

以下の関数も不要なので削除する。

```glsl
get_line_group_visibility()
get_top_edge_group_visibility()
```

これらは現在、

- 波形を複数点サンプリング
- 1px グループ単位で交差判定
- `hit_count`
- `max_wave_y`

によって波線を近似しているが、fragment shader では各ピクセルについて直接波形を評価できるため不要。

---

# 3. 現在の問題点

### 3.1 `line_texture` が完全に未使用

現在、

```glsl
uniform sampler2D line_texture;
```

が存在するが、

```glsl
texture(line_texture, ...)
```

が一度も存在しない。

したがって削除する。

同様に、

```glsl
line_texture_size
line_texture_group_count
```

も現在は実質的に「1px グリッドを作るため」だけに使われているため削除する。

---

### 3.2 world座標とlocal座標が混ざっている

現在の波形は、

```glsl
world_x = origin_x + scaled_x;
wave_phase = world_x * TAU * wave_frequency / mesh_size.x;
```

となっている。

このためオブジェクトの、

- 移動
- scale
- world position

によって波形の位相・周期が変化する。

今回の仕様では波形はテクスチャに固定する。

したがって、

```text
UV
↓
local pixel coordinate
↓
wave
```

だけで計算すること。

---

## 4. ピクセル座標

fragment shader では以下の概念を使用する。

```glsl
vec2 local_pos = UV * mesh_size;
vec2 pixel_pos = floor(local_pos);
vec2 pixel_center = pixel_pos + vec2(0.5);
```

波形および斜線判定には原則として `pixel_center` を使用する。

これにより nearest-neighbor のピクセルアートとして安定させる。

`world_position` は使用しない。

---

# 5. 波形

波形は次式とする。

```text
phase =
    local_x / mesh_width
    * TAU
    * wave_frequency
    + TIME * wave_speed

wave =
    sin(phase)
    * wave_amplitude
    * edge_mask
```

つまり GLSL 的には概ね、

```glsl
float phase =
    pixel_center.x
    * TAU
    * wave_frequency
    / mesh_size.x
    + TIME * wave_speed;

float wave =
    sin(phase)
    * wave_amplitude
    * edge_mask;
```

とする。

`wave_frequency = 15.0` の場合、

**mesh 全体で15周期**

という意味に統一する。

オブジェクトの scale や world position によって周期を変化させない。

---

# 6. 波を必ずメッシュ内部に収める

これは重要。

Fragment Shader は**メッシュの外にはピクセルを生成できない**。

したがって、

```text
y = 0
```

を中心に、

```text
-amplitude ～ +amplitude
```

と波打たせる実装は禁止。

負方向の波がメッシュ外へ出て描画不能になるため。

代わりに上端へ余白を確保する。

新しい uniform を追加する。

```glsl
uniform float wave_base_y = 2.0;
```

波形境界を、

```glsl
float wave_y = wave_base_y + wave;
```

とする。

最低条件は、

```text
wave_base_y >= wave_amplitude + top_edge_thickness / 2
```

とする。

これによって波全体をテクスチャ内部に収める。

---

# 7. 左右端の波停止処理

現在の、

```glsl
edge_keep_width
```

は名前が挙動を表していないので、

```glsl
wave_edge_fade_width
```

へ変更する。

処理自体は、

```glsl
float left_mask =
    smoothstep(
        0.0,
        wave_edge_fade_width,
        pixel_center.x
    );

float right_mask =
    1.0 - smoothstep(
        mesh_size.x - wave_edge_fade_width,
        mesh_size.x,
        pixel_center.x
    );

float edge_mask = left_mask * right_mask;
```

とする。

これにより左右端では振幅0になり、中央だけ波打つ。

---

# 8. 上端境界のクリップ

画面座標と同じく、

```text
Y が小さい = 上
Y が大きい = 下
```

として扱う。

波より下側を内部とする。

```glsl
float inside_wave =
    step(wave_y, pixel_center.y);
```

したがって、

```text
pixel_center.y < wave_y
```

の部分は描画しない。

これが今まで頂点変形で作っていた上端形状の代替になる。

---

# 9. 波線の描画

現在の

```glsl
get_top_edge_group_visibility()
```

による5点サンプリング方式は使用禁止。

各pixelについて波とのY距離を直接計算する。

概念的には、

```glsl
float distance_to_wave =
    abs(pixel_center.y - wave_y);
```

として、

```glsl
float top_edge =
    1.0 - step(
        top_edge_thickness * 0.5,
        distance_to_wave
    );
```

とする。

`top_edge_thickness = 1.0` なら、おおむね1px幅の波線になる。

---

# 10. 斜線

現在の、

```glsl
pixel_uv = floor(world_position);
mod(pixel_uv.x + pixel_uv.y, hatch_period);
```

という考え方自体は使える。

ただし world 座標ではなく local pixel 座標を使う。

```glsl
float hatch_phase =
    mod(
        pixel_pos.x + pixel_pos.y,
        hatch_period
    );

float hatch_value =
    1.0 - step(1.0, hatch_phase);
```

つまり、

```text
x + y
```

による45度斜線を生成する。

斜線は、

```glsl
hatch_value *= inside_wave;
```

として波より上には絶対に描画しないこと。

---

# 11. マスク

元テクスチャによるマスク処理は残す。

ただし現在の最大の問題の一つが、

```glsl
float line_value =
    max(hatch_value_masked, top_edge_value);
```

となっていて、

**top_edge_value に mask_value が掛かっていないこと。**

つまり現在は波線だけ元テクスチャのマスク外へ描画され得る。

必ず最終的に、

```glsl
float pattern =
    max(
        hatch_value * inside_wave,
        top_edge
    );

pattern *= mask_value;
```

とする。

波線・斜線の両方を同じマスクで制限する。

---

# 12. `raw_mask_value` の整理

現在、

```glsl
float raw_mask_value =
    mask_color.a
    * max(
        max(mask_color.r, mask_color.g),
        mask_color.b
    );
```

となっている。

これは、

**RGB輝度とalphaの両方をマスクとして使う**

という特殊な挙動。

一般的な透過テクスチャなら、

```glsl
float raw_mask_value = mask_color.a;
```

で十分。

ただしこれは元テクスチャの仕様に依存する。

Codex は使用しているテクスチャを確認し、

- 透明部分を alpha で表現している → `mask_color.a`
- RGB自体がマスク画像 → RGBを使用

のどちらかへ明示的に統一すること。

現在のような

```glsl
alpha * max(r,g,b)
```

を理由なく維持しない。

---

# 13. Pixel Art 用マスク

現在は、

```glsl
smoothstep(
    mask_clip_threshold,
    mask_clip_threshold + 0.01,
    raw_mask_value
);
```

となっている。

今回の出力は nearest / pixel-art 前提なので、マスクも原則hard clipにする。

```glsl
float mask_value =
    step(mask_clip_threshold, raw_mask_value);
```

半透明アンチエイリアスを意図しているテクスチャの場合のみ `smoothstep` を残す。

---

# 14. 最終合成

最終的な論理構造は以下にする。

```text
UV
 ↓
local pixel coordinate
 ↓
sine wave Y
 ↓
 ┌───────────────┐
 │ inside_wave   │
 │ top_edge      │
 │ hatch         │
 └───────────────┘
 ↓
source texture mask
 ↓
dot_color
 ↓
COLOR
```

概念上、

```glsl
float hatch =
    hatch_value
    * inside_wave;

float line_value =
    max(
        hatch,
        top_edge
    );

line_value *= mask_value;

COLOR = vec4(
    dot_color.rgb,
    line_value * dot_color.a
) * COLOR;
```

とする。

---

# 15. `vertex()` の最終状態

可能なら `vertex()` 自体を削除する。

つまり、

```glsl
void vertex()
```

を定義しない。

波形・斜線・マスク処理はすべて `fragment()` 内で完結させる。

---

# 16. 最終的に残す uniform

おおむね以下だけに整理する。

```glsl
uniform vec4 dot_color : source_color;

uniform vec2 mesh_size;

uniform float hatch_period;

uniform float wave_amplitude;
uniform float wave_frequency;
uniform float wave_speed;
uniform float wave_base_y;
uniform float wave_edge_fade_width;

uniform float top_edge_thickness;

uniform float mask_clip_threshold;
```

削除対象：

```glsl
line_texture
line_texture_size
line_texture_group_count

world_position
world_origin
world_scale
```

---

# 17. 完了条件

Codex 側で以下を確認すること。

1. `VERTEX` を一切変更していない。
2. オブジェクトを移動しても波形の形と位相が変わらない。
3. scale を変更してもテクスチャ内の波の周期数が変わらない。
4. `wave_frequency = 15` なら横幅全体に15周期存在する。
5. 波線がポリゴン状・三角形状にならない。
6. 波線は各X列について直接 `sin()` から決定される。
7. 斜線は波より下だけに存在する。
8. 波線も斜線も元テクスチャのマスク外へ出ない。
9. `line_texture` 関連の死んだコードが残っていない。
10. group単位の5点サンプリング処理が完全に無くなっている。
11. nearest filtering 時に1px単位で安定したパターンになる。
12. geometry の外側へ波を描画しようとしない。