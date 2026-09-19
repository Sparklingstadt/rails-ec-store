# このECストアでRailsを学ぶ

## 1. 商品ページからMVCをつかむ

`GET /products/everyday-mug` は、`config/routes.rb` によって `ProductsController#show` に届きます。Controllerは `Product.published.find_by!(slug: params[:slug])` で公開商品のデータを取得し、`@product` をViewへ渡します。`app/views/products/show.html.erb` はその内容をHTMLにします。

- Model: データ、関連、入力ルール
- View: HTMLと表示の組み立て
- Controller: HTTPリクエストを受け取り、必要な処理へつなぐ

商品が見つからない場合は `find_by!` が例外を発生させ、Railsが404に変換します。

**練習:** 商品詳細に説明項目をひとつ追加してみましょう。DBの項目を増やす場合は既存のmigrationを書き換えず、新しいmigrationを作ります。

## 2. 検索とSQLの関係

`Product.search` は名前・英語名・説明をLIKE検索します。`sanitize_sql_like` で `%` と `_` を通常の文字として扱い、値はプレースホルダーで渡しています。並び替えには `Product::SORTS` の許可リストを使います。

`ProductSearch` は価格を整数として検証し、カテゴリ・キーワード・在庫・価格を組み合わせて絞り込みます。総件数を数え、12件ずつ `limit` / `offset` で取得します。並び順にはIDを含め、同じ価格の商品がページ間で入れ替わるのを防ぎます。不正な価格では結果を空にしてエラーを表示し、意図せず条件を緩めません。

**練習:** `test/integration/product_search_test.rb` を読み、上限と下限が同じとき、最終ページを超えたときの動作を説明してみましょう。

## 3. カートの計算と保存先を分ける

`Cart` は `ApplicationRecord` を継承しないRubyクラスです。`{ "1" => 2 }` のような商品IDと数量だけを保存し、`Cart#items` が公開商品をDBから読み出します。会員はUserのJSON列、ゲストは暗号化Cookieセッションを保存先として使います。

価格をCookieやhidden inputから取得しないのは、ブラウザから送られる値を信頼しないためです。小計と送料はサーバー側で計算します。Cookieにはサイズ制限があります。大規模なカタログや複数端末の同時操作へ発展させる場合は、Cart・CartItemを独立したDBテーブルにする設計が適しています。

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

`ChangeOrderStatus` は注文をロックし、受付済みから発送済みまたはキャンセル済みへの遷移だけを認めます。同じ状態への再送信は何もしません。在庫戻しと状態保存は同じトランザクション内なので、途中で失敗すれば両方戻ります。

**練習:** 発送とキャンセルが同時に届いたときのテストを読み、両方を成功させない理由を説明してみましょう。

## 5. 注文履歴と所有者

ゲストにはランダムな `buyer_key` を発行し、暗号化CookieセッションとDBの注文に保存します。ゲストは `Order.where(user_id: nil, buyer_key: buyer_key)`、会員は `current_user.orders` から注文を探します。注文番号だけ知っていても、他の利用者は閲覧・キャンセルできません。

ログイン時は `ClaimGuestData` が、そのブラウザの未紐付け注文だけを会員へ移します。メールアドレスが一致するだけでは注文を取得しません。カートの数量は合計して上限20に収め、お気に入りは重複を除きます。移行後はCookieセッションを更新するため、再ログイン時に二重移行しません。

## 6. 認証と管理者権限

Userは `has_secure_password` でBCryptのダイジェストを保存します。ログイン時は `authenticate_by` を使い、存在しないメールでも汎用的なエラーを返します。サーバー上の `LoginSession` と署名Cookieを対応付け、ログアウト時にセッションを破棄します。登録・ログインの試行回数はIP単位で制限しています。

管理Controllerはログイン確認に加えて `current_user.admin?` を確認します。登録・プロフィール更新のStrong Parametersには `admin` を含めません。ボタンを隠すだけでなく、URLを直接操作しても403にすることが必要です。

商品は `lock_version` による楽観的ロックを使います。注文・キャンセルも在庫と同時にバージョンを増やすため、古い編集画面から在庫を上書きしようとすると409で最新値を表示します。非公開商品は一覧・詳細・カート・注文処理のすべてで除外します。

## 7. フォームとバリデーション

ブラウザの `required` は使いやすさのため、Modelの `validates` はサーバー上のデータ整合性のために存在します。HTMLの制約を外して送信されてもModelが検証します。

日本語のメッセージは `config/locales/ja.yml` で管理しています。422のレスポンスで入力画面を再表示すると、入力した値とエラーをそのまま確認できます。

**練習:** 電話番号を追加する場合、migration、Strong Parameters、Model、フォーム、サンプル入力、テストのどこが変わるか考えてから実装してみましょう。

## 8. テストを読む

- `test/models/cart_test.rb`: 数量、在庫、送料などの境界
- `test/services/place_order_test.rb`: 注文内容の保存、在庫不足時のロールバック、二重送信
- `test/integration/store_flow_test.rb`: URLを通じた購入フロー、所有者の制限、入力エラー
- `test/integration/authentication_test.rb`: 登録、認証、ログアウト、権限の改ざん防止
- `test/integration/member_store_test.rb`: ゲストデータ移行、会員の保存先・閲覧権限
- `test/integration/admin_products_test.rb`: 商品管理権限、非公開商品の除外、在庫競合
- `test/integration/order_status_test.rb`: 注文状態の遷移、キャンセルと在庫
- `test/services/concurrent_orders_test.rb`: 別スレッド・別DB接続による同時注文・同時キャンセル
- `test/integration/product_search_test.rb`: 価格境界、検索条件の組み合わせ、ページ切り替え

テストは「メソッドが呼ばれたか」より「利用者やデータに何が起きたか」を確認しています。

**練習:** 先に「在庫0の商品をカートに追加してもカートは空のまま」というテストを読んで、ブラウザ上の同じ場面と対応付けてください。

## 9. ポートフォリオで説明できること

- なぜ金額をブラウザから受け取らないのか
- なぜ注文明細に商品名・単価をコピーするのか
- 在庫不足になったとき、すべてを元に戻す方法
- 二重送信と同時注文の違い
- 別の利用者の注文を表示させないための絞り込み
- 認証（誰か）と認可（何をしてよいか）の違い
- 悲観的ロックと楽観的ロックを使う場面
- SQLite・Cookie・JSON列・プロセス内レート制限の範囲と限界

READMEの「実装の範囲」を土台に、未実装の機能までできたと説明せず、実際に検証できた内容を作品紹介にまとめてください。

## 次に取り組むなら

今回の5段階は [実装順序](ROADMAP.md) を参照してください。さらに進める場合の候補です。

1. メール認証とパスワード再設定
2. Active Storageによる画像アップロード
3. カート・お気に入りのテーブル分離と複数端末の同時更新
4. 決済サービスのテストモードとWebhookの冪等処理
5. CIでの実ブラウザテストと本番用DB・バックアップの設計

公式の学習資料: [Rails Guides](https://guides.rubyonrails.org/)、[Getting Started](https://guides.rubyonrails.org/getting_started.html)、[Active Record Transactions](https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html)。
