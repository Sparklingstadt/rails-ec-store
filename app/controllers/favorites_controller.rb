class FavoritesController < ApplicationController
  def index
    @products = Product.where(id: favorite_ids).order(:position)
  end

  def create
    product = Product.find(params[:product_id])
    session[:favorites] = (favorite_ids + [ product.id ]).uniq.last(50)
    redirect_back fallback_location: favorites_path, allow_other_host: false, notice: "お気に入りに追加しました。", status: :see_other
  end

  def destroy
    session[:favorites] = favorite_ids - [ params[:id].to_i ]
    redirect_back fallback_location: favorites_path, allow_other_host: false, notice: "お気に入りから削除しました。", status: :see_other
  end
end
