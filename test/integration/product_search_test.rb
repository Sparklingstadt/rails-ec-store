require "test_helper"

class ProductSearchTest < ActionDispatch::IntegrationTest
  test "price boundaries are inclusive and combine with category keyword and stock" do
    get products_path, params: { min_price: 2400, max_price: 2400, category: "tableware", q: "マグ", in_stock: "1" }
    assert_response :success
    assert_select ".product-card", count: 1
    assert_select ".product-card h3", text: "日々のマグカップ"
    products(:mug).update!(stock: 0)
    get products_path, params: { in_stock: "1" }
    assert_select ".product-card", count: 1
    assert_select ".product-card h3", text: "一輪挿し しずく"
    get products_path, params: { min_price: 2500, max_price: 3000 }
    assert_select ".empty-state"
  end

  test "malformed or reversed prices show errors without broadening the search" do
    [ { min_price: "1 OR 1=1" }, { min_price: "-1" }, { max_price: "2.5" }, { min_price: "999999999999" }, { min_price: 4000, max_price: 2000 } ].each do |filters|
      get products_path, params: filters
      assert_response :success
      assert_select ".form-errors[role=alert]"
      assert_select ".product-card", count: 0
    end
  end

  test "pagination is stable bounded and carries every active filter" do
    13.times do |index|
      Product.create!(products(:mug).attributes.except("id", "created_at", "updated_at").merge(slug: "pagination-#{index}", name: "ページ用マグ#{index}", position: index + 10))
    end
    filters = { category: "tableware", q: "マグ", collection: "new", min_price: 2000, max_price: 3000, in_stock: "1", sort: "price_asc" }
    get products_path, params: filters
    assert_select ".product-card", count: 12
    first_page = css_select(".product-card h3").map(&:text)
    href = css_select(".pagination a[rel=next]").first["href"]
    filters.each { |key, value| assert_equal value.to_s, Rack::Utils.parse_query(URI.parse(href).query)[key.to_s] }
    get href
    assert_select ".product-card", count: 2
    assert_empty first_page & css_select(".product-card h3").map(&:text)
    assert_select ".pagination a[rel=next]", count: 0
    assert_select ".pagination a[rel=prev]", count: 1
    get products_path, params: filters.merge(page: 999)
    assert_select ".pagination [aria-current=page]", text: "2 / 2 ページ"
    get products_path, params: filters.merge(page: "invalid")
    assert_select ".product-card", count: 12
    assert_select ".sort-form input[name=min_price][value='2000']"
    category_href = css_select(".category-nav a").last["href"]
    assert_equal "2000", Rack::Utils.parse_query(URI.parse(category_href).query)["min_price"]
  end

  test "unpublished products are absent from filtered totals" do
    products(:mug).update!(published: false)
    get products_path, params: { in_stock: "1", min_price: 0 }
    assert_select ".product-card", count: 1
    assert_select ".collection-options span", text: /1 items/
    get root_path, params: { max_price: 1000 }
    assert_select ".hero", count: 0
  end
end
