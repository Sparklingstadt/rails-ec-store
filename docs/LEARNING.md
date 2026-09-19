# このECストアでRailsを学ぶ

## 1. 商品ページからMVCをつかむ

`GET /products/everyday-mug` は、`config/routes.rb` によって `ProductsController#show` に届きます。Controllerは `Product.find_by!(slug: params[:slug])` でデータを取得し、`@product` をViewへ渡します。`app/views/products/show.html.erb` はその内容をHTMLにします。

- Model: データ、関連、入力ルール
- View: HTMLと表示の組み立て
- Controller: HTTPリクエストを受け取り、必要な処理へつなぐ

商品が見つからない場合は `find_by!` が例外を発生させ、Railsが404に変換します。

**練習:** 商品詳細に説明項目をひとつ追加してみましょう。DBの項目を増やす場合は既存のmigrationを書き換えず、新しいmigrationを作ります。

## 2. 検索とSQLの関係

`Product.search` は名前・英語名・説明をLIKE検索します。`sanitize_sql_like` で `%` と `_` を通常の文字として扱い、値はプレースホルダーで渡しています。並び替えには `Product::SORTS` の許可リストを使います。

**練習:** 「在庫ありのみ」のチェックボックスを追加し、`where("stock > 0")` で絞り込んでください。検索・カテゴリとの組み合わせをテストしてみましょう。

## 3. カートはデータベースに保存していない

`Cart` は `ApplicationRecord` を継承しないRubyクラスです。Cookieセッションには `{ "1" => 2 }` のような商品IDと数量だけを保存し、`Cart#items` がDBから商品を読み出します。

価格をCookieやhidden inputから取得しないのは、ブラウザから送られる値を信頼しないためです。小計と送料はサーバー側で計算します。Cookieにはサイズ制限があるため、大規模なカタログやログイン機能へ発展させる場合はCart・CartItemをDBへ移す設計が適しています。

**練習:** 送料を変えた際に、金額境界のテストが正しく失敗し、修正後に通ることを確認してください。

## 4. 注文処理をサービスにまとめる

`OrdersController#create` は配送先だけをStrong Parametersで許可して `PlaceOrder.call` に渡します。

```text
フォーム → checkout_keyを検証 → 同じ注文があれば返す
                             ↓
                       トランザクション開始
                             ↓
                       注文情報を検証・保存
                             ↓
                       商品の最新価格を取得
                             ↓
                       stock >= 数量を条件に在庫減算
                             ↓
                       商品名・単価を明細へコピー
                             ↓
                       送料と合計を計算して保存
                             ↓
                       コミット → カートを空にする
```

途中で在庫が足りなければ例外を投げ、注文・全明細・在庫変更のすべてをロールバックします。単なる `if stock >= quantity` の後の更新では、並行リクエストが同じ在庫を読めてしまいます。このアプリでは条件付きUPDATEとDBのCHECK制約を併用しています。

`checkout_key` は注文テーブルで一意です。同じフォームの再送信を既存注文として扱い、二度目の在庫減算を防ぎます。カート変更時はキーを無効にし、変更前のフォームからの注文を拒否します。

**練習:** 注文に `status` を追加し、受付済み・キャンセルを表現してみましょう。キャンセル時の在庫戻しも一度だけ行われるように設計してください。

## 5. 注文履歴と所有者

ランダムな `buyer_key` をRailsの暗号化Cookieセッションへ保存し、DBの注文にも付与します。注文詳細は `Order.where(buyer_key: buyer_key)` から探します。注文番号だけ知っていても、別ブラウザからは閲覧できません。

これは会員認証ではありません。Cookieを失うと過去の履歴にアクセスできなくなります。学習を進める際はUserモデルと認証を導入し、注文をUserへ関連付けてください。

## 6. フォームとバリデーション

ブラウザの `required` は使いやすさのため、Modelの `validates` はサーバー上のデータ整合性のために存在します。HTMLの制約を外して送信されてもModelが検証します。

日本語のメッセージは `config/locales/ja.yml` で管理しています。422のレスポンスで入力画面を再表示すると、入力した値とエラーをそのまま確認できます。

**練習:** 電話番号を追加する場合、migration、Strong Parameters、Model、フォーム、サンプル入力、テストのどこが変わるか考えてから実装してみましょう。

## 7. テストを読む

- `test/models/cart_test.rb`: 数量、在庫、送料などの境界
- `test/services/place_order_test.rb`: 注文内容の保存、在庫不足時のロールバック、二重送信
- `test/integration/store_flow_test.rb`: URLを通じた購入フロー、所有者の制限、入力エラー

テストは「メソッドが呼ばれたか」より「利用者やデータに何が起きたか」を確認しています。

**練習:** 先に「在庫0の商品をカートに追加してもカートは空のまま」というテストを読んで、ブラウザ上の同じ場面と対応付けてください。

## 8. ポートフォリオで説明できること

- なぜ金額をブラウザから受け取らないのか
- なぜ注文明細に商品名・単価をコピーするのか
- 在庫不足になったとき、すべてを元に戻す方法
- 二重送信と同時注文の違い
- 別の利用者の注文を表示させないための絞り込み
- SQLiteとゲストセッションを採用した範囲・限界

READMEの「実装の範囲」を土台に、未実装の機能までできたと説明せず、実際に検証できた内容を作品紹介にまとめてください。

## 次に取り組むなら

1. 会員認証とUserに紐づく注文履歴
2. 管理者のみ操作できる商品の登録・更新画面
3. カテゴリや画像を別テーブルで管理
4. 決済サービスのテストモードとWebhookの冪等処理
5. 注文ステータスとキャンセル・在庫戻し

公式の学習資料: [Rails Guides](https://guides.rubyonrails.org/)、[Getting Started](https://guides.rubyonrails.org/getting_started.html)、[Active Record Transactions](https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html)。
