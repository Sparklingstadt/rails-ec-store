class RegistrationsController < ApplicationController
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  rate_limit to: 10, within: 10.minutes, only: :create, store: RATE_LIMIT_STORE,
    with: -> { redirect_to new_registration_path, alert: "登録の試行回数が多くなっています。しばらくお待ちください。" }

  def new
    return redirect_to account_path if current_user
    @user = User.new
  end

  def create
    return redirect_to account_path if current_user
    @user = User.new(params.require(:user).permit(:name, :email, :password, :password_confirmation))
    if @user.save
      start_login(@user)
      redirect_to account_path, notice: "会員登録が完了しました。", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @user.errors.add(:email, :taken)
    render :new, status: :unprocessable_entity
  end
end
