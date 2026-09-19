# 既存商品の在庫や価格を上書きしない、安全に再実行できるサンプルデータ。
products = [
  { slug: "everyday-mug", name: "日々のマグカップ", english_name: "Everyday mug", category: "tableware", image: "mug.png", price: 2400, stock: 24, color: "アイボリー", material: "陶器", size: "約φ8.5 × H9cm / 300ml", featured: true, description: "両手で包み込みたくなる、やわらかなかたち。土の粒がのぞく自然な表情と、手に馴染む大きめの持ち手。朝のコーヒーから夜のハーブティーまで、日々のひと息に寄り添うマグです。" },
  { slug: "quiet-vase", name: "一輪挿し しずく", english_name: "Quiet vase", category: "interior", image: "vase.png", price: 3800, stock: 12, color: "チョークホワイト", material: "陶器", size: "約φ11 × H18cm", featured: true, description: "窓辺に、季節をひと枝。しずくのような柔らかな輪郭とマットな質感が、草花の表情を引き立てます。何も挿さずに置いても、静かな存在感のある一輪挿しです。植物は付属しません。" },
  { slug: "linen-cloths", name: "リネンクロス 2枚セット", english_name: "Linen cloth set", category: "textile", image: "linen.png", price: 2800, stock: 18, color: "ナチュラル / オリーブ", material: "麻100%", size: "各 約45 × 65cm", featured: false, description: "洗うたび、使うたびに、くったりとやわらかく。器を拭く、かごに掛ける、ランチョンマットにする。暮らしのさまざまな場面で活躍する、2色のリネンクロスです。" },
  { slug: "oak-tray", name: "オークのラウンドトレイ セット", english_name: "Oak tray set", category: "tableware", image: "tray.png", price: 5600, stock: 8, color: "ナチュラル", material: "オーク材 / オイル仕上げ", size: "約φ24cm・φ28cm / 2枚セット", featured: false, description: "木目のぬくもりを食卓に。朝食やティータイムにちょうどよい、大小2枚のトレイセット。縁をわずかに立ち上げた、すっきりとした佇まいです。" },
  { slug: "amber-candle", name: "ソイキャンドル 木漏れ日", english_name: "Amber soy candle", category: "fragrance", image: "candle.png", price: 3200, stock: 5, color: "アンバー", material: "ソイワックス / ガラス / 木製蓋", size: "約φ7 × H8cm / 160g", featured: true, description: "一日の終わり、照明を少し落として。アンバーのガラスを通る穏やかな灯りと、ウッディな香りをイメージしたキャンドル。自分のための静かな時間をつくります。" },
  { slug: "slow-coffee", name: "スローコーヒー ドリッパーセット", english_name: "Slow coffee set", category: "tableware", image: "dripper.png", price: 4800, stock: 10, color: "アイボリー", material: "陶器 / 耐熱ガラス / 木", size: "1〜2杯用 / サーバー容量400ml", featured: false, description: "お湯を注ぐ、香りを待つ。それだけの時間が、朝を少し特別にしてくれる。陶器のドリッパーとガラスサーバーを組み合わせた、コーヒーのための道具です。" }
]
products.each_with_index do |attributes, index|
  Product.find_or_create_by!(slug: attributes[:slug]) do |product|
    product.assign_attributes(attributes.merge(position: index))
  end
end
puts "商品 #{Product.count}件を用意しました。"
