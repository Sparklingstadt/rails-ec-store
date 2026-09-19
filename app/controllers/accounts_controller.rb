class AccountsController < ApplicationController
  before_action :require_login
  before_action -> { response.headers["Cache-Control"] = "no-store" }

  def show
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(params.require(:user).permit(:name, :postal_code, :prefecture, :address))
      redirect_to account_path, notice: "お届け先を保存しました。", status: :see_other
    else
      render :show, status: :unprocessable_entity
    end
  end
end
