module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [ :edit, :update ]

    def index
      @products = Product.order(:position, :id)
    end

    def new
      @product = Product.new(category: "tableware", image: "mug.png", stock: 0, position: 0, published: false)
    end

    def create
      @product = Product.new(product_params)
      if @product.save
        redirect_to admin_products_path, notice: "商品を登録しました。", status: :see_other
      else
        render :new, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotUnique
      @product.errors.add(:slug, :taken)
      render :new, status: :unprocessable_entity
    end

    def edit
    end

    def update
      if @product.update(product_params)
        redirect_to admin_products_path, notice: "商品を更新しました。", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    rescue ActiveRecord::StaleObjectError
      @product.reload
      flash.now[:alert] = "注文や別の編集によって商品が更新されました。最新の値を表示しています。確認してから保存してください。"
      render :edit, status: :conflict
    rescue ActiveRecord::RecordNotUnique
      @product.errors.add(:slug, :taken)
      render :edit, status: :unprocessable_entity
    end

    private

    def set_product
      @product = Product.find_by!(slug: params[:slug])
    end

    def product_params
      params.require(:product).permit(:name, :english_name, :slug, :category, :image, :description, :material, :size, :color, :price, :stock, :position, :featured, :published, :lock_version)
    end
  end
end
