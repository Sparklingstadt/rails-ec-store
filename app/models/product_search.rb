class ProductSearch
  PER_PAGE = 12
  attr_reader :category, :query, :sort, :collection, :min_price, :max_price, :in_stock, :errors, :page, :total_count, :total_pages, :products

  def initialize(params)
    @category = params[:category].presence_in(Product::CATEGORIES.keys)
    @query = params[:q].to_s.strip.first(100)
    @sort = params[:sort].presence_in(Product::SORTS.keys) || "recommended"
    @collection = params[:collection].presence_in([ "new" ])
    @min_price = params[:min_price].to_s.strip.first(30)
    @max_price = params[:max_price].to_s.strip.first(30)
    @in_stock = params[:in_stock] == "1"
    @errors = []

    minimum = price_value(min_price, "最低価格")
    maximum = price_value(max_price, "最高価格")
    errors << "最低価格は最高価格以下にしてください。" if minimum && maximum && minimum > maximum
    scope = Product.published.search(query)
    scope = scope.where(category: category) if category
    scope = scope.where(featured: true) if collection == "new"
    scope = scope.where("price >= ?", minimum) if minimum
    scope = scope.where("price <= ?", maximum) if maximum
    scope = scope.where("stock > 0") if in_stock
    scope = scope.none if errors.any?
    @total_count = scope.count
    @total_pages = [ (total_count.to_f / PER_PAGE).ceil, 1 ].max
    @page = params[:page].to_s.match?(/\A\d{1,9}\z/) ? params[:page].to_i.clamp(1, total_pages) : 1
    @products = scope.order(Product::SORTS.fetch(sort)).limit(PER_PAGE).offset((page - 1) * PER_PAGE)
  end

  def filters
    { category: category, q: query.presence, sort: sort, collection: collection, min_price: min_price.presence, max_price: max_price.presence, in_stock: in_stock ? "1" : nil }.compact
  end

  def filtered?
    category.present? || query.present? || collection.present? || min_price.present? || max_price.present? || in_stock
  end

  private

  def price_value(value, label)
    return if value.blank?
    unless value.match?(/\A\d{1,9}\z/)
      errors << "#{label}は0〜999,999,999円の整数で入力してください。"
      return
    end
    value.to_i
  end
end
