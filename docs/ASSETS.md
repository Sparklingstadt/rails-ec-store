# 画像と生成プロンプト

すべてCodexの内蔵imagegenツールでこのプロジェクト用に生成しました。外部サイトの写真はアプリに使用していません。実在の商品写真ではありません。生成画像は下記へコピー済みで、元の生成ディレクトリへの依存はありません。

| 保存先 | 用途 |
| --- | --- |
| `public/images/hero.png` | トップとストア紹介のメイン写真 |
| `public/images/mug.png` | 日々のマグカップ |
| `public/images/vase.png` | 一輪挿し しずく |
| `public/images/linen.png` | リネンクロス2枚セット |
| `public/images/tray.png` | オークのトレイ2枚セット |
| `public/images/candle.png` | ソイキャンドル |
| `public/images/dripper.png` | コーヒードリッパーセット |

## メイン写真のプロンプト

```text
Use case: photorealistic-natural. Asset: wide hero photograph for a Japanese independent home goods shop called Yohaku. Create a premium editorial still life, landscape 3:2. A sculptural ivory ceramic pitcher with a single olive branch, one handmade beige coffee cup with a small saucer, loosely folded natural flax linen on a honey oak table. Warm sunlight enters from the upper left and creates dramatic clean diagonal shadows on a textured pale plaster wall. Small wooden stool barely visible on right edge. Natural Japanese design magazine photography, tactile, quiet, beautifully composed, real photographic materials, subtle grain, not a 3D render. Center objects around the right half, table in bottom third. No people, no text, no logos, no border.
```

## 商品写真の共通プロンプト

以下の `{subject}` に表の内容を挿入し、各画像を個別に生成しています。

```text
Use case: product-mockup. Asset: square product catalog photograph for a Japanese curated home goods store. Subject: {subject}. Clean premium editorial studio product photograph, centered full object with generous negative space around all sides, soft warm gray/off-white seamless backdrop, daylight from upper left, realistic fine material detail, soft shadow below. Camera at a slightly elevated three-quarter angle. Only this product, no decor, no typography, no logos or watermarks. Photorealistic, high-end design magazine, restrained, tactile. Square composition.
```

| ファイル | subject |
| --- | --- |
| mug.png | a single handmade speckled ivory ceramic coffee mug, rounded cylindrical shape, large curved handle, empty |
| vase.png | a single sculptural chalk white ceramic vase with a narrow neck, with one delicate olive twig |
| linen.png | two beautifully folded washed natural flax linen kitchen cloths, one oatmeal and one dusty olive |
| tray.png | a single round honey-colored solid oak serving tray with a small raised rim, standing partly upright on a matching flat tray |
| candle.png | a single unlit soy candle in a low amber glass jar with no label, a small wooden lid resting next to it |
| dripper.png | an ivory ridged ceramic pour-over coffee dripper sitting on a small clear glass coffee server with a wooden collar |

アイコンは外部ライブラリに依存しない線画SVGです。フォントはOS標準の日本語フォントとセリフ・サンセリフのフォールバックを使用します。
