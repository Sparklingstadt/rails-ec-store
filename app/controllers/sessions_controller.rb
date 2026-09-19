class SessionsController < ApplicationController
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  rate_limit to: 10, within: 3.minutes, only: :create, store: RATE_LIMIT_STORE,
    with: -> { redirect_to new_session_path, alert: "ログインの試行回数が多くなっています。3分ほどお待ちください。" }

  def new
    redirect_to account_path if current_user
  end

  def create
    return redirect_to account_path if current_user
    if user = User.authenticate_by(email: params[:email].to_s, password: params[:password].to_s)
      start_login(user)
      redirect_to account_path, notice: "ログインしました。", status: :see_other
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが正しくありません。"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    finish_login
    redirect_to root_path, notice: "ログアウトしました。", status: :see_other
  end
end
