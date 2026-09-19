module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user
  end

  private

  def current_login_session
    return @current_login_session if defined?(@current_login_session)
    @current_login_session = LoginSession.active.includes(:user).find_by(id: cookies.signed[:login_session_id])
  end

  def current_user
    current_login_session&.user
  end

  def require_login
    redirect_to new_session_path, alert: "ログインしてご利用ください。" unless current_user
  end

  def start_login(user)
    guest_cart = session[:cart]
    guest_favorites = session[:favorites]
    guest_buyer = session[:buyer_key]
    ClaimGuestData.call(user: user, cart_data: guest_cart, favorite_ids: guest_favorites, buyer_key: guest_buyer)
    current_login_session&.destroy!
    reset_session
    @current_cart = nil
    @current_login_session = user.login_sessions.create!(expires_at: 30.days.from_now)
    cookies.signed[:login_session_id] = { value: @current_login_session.id, expires: @current_login_session.expires_at, httponly: true, same_site: :lax, secure: Rails.env.production? }
  end

  def finish_login
    current_login_session&.destroy!
    cookies.delete(:login_session_id)
    reset_session
    @current_login_session = nil
  end
end
